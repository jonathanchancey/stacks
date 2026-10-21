package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"golang.org/x/oauth2"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	clientapi "k8s.io/client-go/tools/clientcmd/api"
)

var version = "dev"

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string) error {
	cmd := "serve"
	if len(args) > 0 && !strings.HasPrefix(args[0], "-") {
		cmd = args[0]
		args = args[1:]
	}
	if cmd == "version" {
		fmt.Println(version)
		return nil
	}
	f := flag.NewFlagSet(cmd, flag.ContinueOnError)
	configFile := f.String("config", "", "server configuration file")
	kubeconfig := f.String("kubeconfig", "", "server kubeconfig; default in-cluster")
	endpoint := f.String("url", "", "service https url")
	tokenFile := f.String("token-file", "", "requester token file, or - for stdin")
	id := f.String("id", "", "request id")
	profile := f.String("profile", "", "profile name")
	namespace := f.String("namespace", "", "target namespace")
	duration := f.String("duration", "30m", "requested duration")
	reason := f.String("reason", "", "reason for access")
	key := f.String("idempotency-key", "", "stable unique request key (required for request)")
	output := f.String("output", "", "new credential kubeconfig file")
	if err := f.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}
	if f.NArg() != 0 {
		return errors.New("unexpected positional arguments")
	}
	if cmd == "serve" {
		cfg, err := loadConfig(*configFile)
		if err != nil {
			return err
		}
		var rc *rest.Config
		if *kubeconfig == "" {
			rc, err = rest.InClusterConfig()
		} else {
			rc, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)
		}
		if err != nil {
			return err
		}
		rc.Timeout = 15 * time.Second
		rc.UserAgent = "escalation/" + version
		k, err := kubernetes.NewForConfig(rc)
		if err != nil {
			return err
		}
		d, err := dynamic.NewForConfig(rc)
		if err != nil {
			return err
		}
		ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
		defer stop()
		slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stderr, nil)))
		// Bound discovery/JWKS HTTP operations, including those initiated outside
		// an incoming request during startup.
		client := &http.Client{Timeout: 10 * time.Second}
		authCtx := context.WithValue(ctx, oauth2.HTTPClient, client)
		auth, err := NewAuth(authCtx, cfg.Issuers, cfg.Human, cfg.BaseURL)
		if err != nil {
			return err
		}
		a := &App{config: cfg, kube: k, store: newStore(d, cfg.Namespace), auth: auth, now: time.Now}
		go a.run(ctx)
		server := &http.Server{Addr: cfg.Listen, Handler: a.handler(), ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 25 * time.Second, WriteTimeout: 30 * time.Second, IdleTimeout: 60 * time.Second, MaxHeaderBytes: 32 * 1024}
		go func() {
			<-ctx.Done()
			shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			_ = server.Shutdown(shutdown)
		}()
		err = server.ListenAndServe()
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return err
	}
	switch cmd {
	case "request", "status", "credentials", "revoke":
	default:
		return errors.New("commands: serve, request, status, credentials, revoke, version")
	}
	if cmd == "credentials" && *output == "" {
		return errors.New("--output is required for credentials")
	}
	u, err := url.Parse(*endpoint)
	if err != nil || u.Scheme != "https" || u.Host == "" || u.User != nil || u.RawQuery != "" || u.Fragment != "" {
		return errors.New("--url must be an https service url")
	}
	var b []byte
	if *tokenFile == "-" {
		b, err = io.ReadAll(io.LimitReader(os.Stdin, 65537))
	} else if *tokenFile != "" {
		b, err = os.ReadFile(*tokenFile)
	} else {
		return errors.New("--token-file is required")
	}
	if err != nil {
		return err
	}
	token := strings.TrimSpace(string(b))
	if token == "" || len(token) > 65536 {
		return errors.New("invalid requester token")
	}
	method := http.MethodPost
	path := "/v1/requests"
	var payload any
	if cmd == "request" {
		payload = createInput{*profile, *namespace, *duration, *reason}
	} else {
		if *id == "" || strings.ContainsAny(*id, "/?#") {
			return errors.New("valid --id is required")
		}
		path += "/" + *id
		switch cmd {
		case "status":
			method = http.MethodGet
		case "credentials":
			path += "/credentials"
		case "revoke":
			path += "/revoke"
		}
	}
	var body bytes.Buffer
	if payload != nil {
		_ = json.NewEncoder(&body).Encode(payload)
	}
	req, err := http.NewRequest(method, strings.TrimSuffix(*endpoint, "/")+path, &body)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	if cmd == "request" {
		req.Header.Set("Idempotency-Key", *key)
	}
	client := &http.Client{Timeout: 30 * time.Second, CheckRedirect: func(r *http.Request, via []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Do(req)
	if err != nil {
		return errors.New("service request failed")
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("service returned status %d; check request status before retrying", resp.StatusCode)
	}
	if cmd != "credentials" {
		_, err = io.Copy(os.Stdout, io.LimitReader(resp.Body, 2<<20))
		return err
	}
	var cred Credential
	if err = json.NewDecoder(io.LimitReader(resp.Body, 65536)).Decode(&cred); err != nil {
		return errors.New("invalid credential response")
	}
	if !time.Now().Before(cred.Expiration) || cred.Token == "" || len(cred.CAData) == 0 {
		return errors.New("invalid or expired credential response")
	}
	serverURL, err := url.Parse(cred.Server)
	if err != nil || serverURL.Scheme != "https" || serverURL.Host == "" || serverURL.User != nil {
		return errors.New("credential endpoint must be https")
	}
	kc := clientapi.NewConfig()
	kc.Clusters["grant"] = &clientapi.Cluster{Server: cred.Server, CertificateAuthorityData: cred.CAData, TLSServerName: cred.TLSName}
	kc.AuthInfos["grant"] = &clientapi.AuthInfo{Token: cred.Token}
	kc.Contexts["grant"] = &clientapi.Context{Cluster: "grant", AuthInfo: "grant"}
	kc.CurrentContext = "grant"
	data, err := clientcmd.Write(*kc)
	if err != nil {
		return err
	}
	file, err := os.OpenFile(*output, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return err
	}
	_, writeErr := file.Write(data)
	closeErr := file.Close()
	if writeErr != nil {
		_ = os.Remove(*output)
		return writeErr
	}
	return closeErr
}
