package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"k8s.io/client-go/tools/clientcmd"
)

func TestCredentialCLI(t *testing.T) {
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" || r.URL.Path != "/v1/requests/request-test/credentials" || r.Header.Get("Authorization") != "Bearer requester-secret" {
			http.Error(w, "unauthorized", 401)
			return
		}
		_ = json.NewEncoder(w).Encode(Credential{Token: "grant-secret", Expiration: time.Now().Add(time.Minute), Server: "https://api.example", CAData: []byte("configured-ca"), TLSName: "api.example"})
	}))
	defer server.Close()
	transport := http.DefaultTransport
	http.DefaultTransport = server.Client().Transport
	defer func() { http.DefaultTransport = transport }()
	dir := t.TempDir()
	tokenFile := filepath.Join(dir, "requester")
	output := filepath.Join(dir, "grant.kubeconfig")
	if err := os.WriteFile(tokenFile, []byte("requester-secret\n"), 0600); err != nil {
		t.Fatal(err)
	}
	stdout, err := os.CreateTemp(dir, "stdout")
	if err != nil {
		t.Fatal(err)
	}
	defer stdout.Close()
	previous := os.Stdout
	os.Stdout = stdout
	defer func() { os.Stdout = previous }()
	args := []string{"credentials", "--url", server.URL, "--token-file", tokenFile, "--id", "request-test", "--output", output}
	if err = run(args); err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(output)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0600 {
		t.Fatalf("credential mode %o", info.Mode().Perm())
	}
	config, err := clientcmd.LoadFromFile(output)
	if err != nil {
		t.Fatal(err)
	}
	if config.CurrentContext != "grant" || config.AuthInfos["grant"].Token != "grant-secret" || string(config.Clusters["grant"].CertificateAuthorityData) != "configured-ca" || config.Clusters["grant"].TLSServerName != "api.example" {
		t.Fatal("incorrect isolated kubeconfig")
	}
	if err = run(args); err == nil {
		t.Fatal("overwrote existing credentials")
	}
	if info, err = stdout.Stat(); err != nil || info.Size() != 0 {
		t.Fatal("credential cli wrote to stdout")
	}
}

func TestCLIErrorDetails(t *testing.T) {
	for _, tc := range []struct {
		name, body, want string
		status           int
	}{
		{"pending", `{"error":"request is awaiting approval"}`, "409: request is awaiting approval", 409},
		{"closed pickup", `{"error":"credential pickup window has closed; request access again"}`, "410: credential pickup window has closed", 410},
		{"proxy error", `<html>upstream unavailable</html>`, "status 502; check request status", 502},
	} {
		t.Run(tc.name, func(t *testing.T) {
			server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(tc.status)
				_, _ = w.Write([]byte(tc.body))
			}))
			defer server.Close()
			previous := http.DefaultTransport
			http.DefaultTransport = server.Client().Transport
			defer func() { http.DefaultTransport = previous }()
			tokenFile := filepath.Join(t.TempDir(), "requester")
			if err := os.WriteFile(tokenFile, []byte("requester-secret"), 0600); err != nil {
				t.Fatal(err)
			}
			err := run([]string{"credentials", "--url", server.URL, "--token-file", tokenFile, "--id", "request-test", "--output", filepath.Join(t.TempDir(), "grant.kubeconfig")})
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("expected actionable error containing %q, got %v", tc.want, err)
			}
		})
	}
}
