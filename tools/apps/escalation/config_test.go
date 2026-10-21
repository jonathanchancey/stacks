package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"sigs.k8s.io/yaml"
)

func TestLoadConfig(t *testing.T) {
	const minimal = `
baseURL: https://access.example.org/
requesters:
  - url: https://agents.example.org
    audience: broker-audience
    requiredClaims:
      project: photos
approverLogin:
  url: https://login.example.org
  clientID: approval-client
issuedCredentials:
  audience: cluster-audience
  server: https://127.0.0.1:6443
  tlsName: private-api.example.org
profiles:
  - name: inspect
    role: {kind: ClusterRole, name: storage-inspect}
    cluster: true
    requesterIssuers: [https://agents.example.org]
    approverGroups: [storage-approvers]
    maxDuration: 30m
    pendingDuration: 15m
`
	for _, tc := range []struct {
		name string
		edit func(map[string]any)
		env  string
		err  string
	}{
		{name: "runtime defaults", env: "auth-system"},
		{name: "explicit overrides", env: "ignored", edit: func(c map[string]any) {
			c["namespace"], c["grantNamespace"] = "broker", "temporary-grants"
			c["listen"], c["clockSkewSeconds"] = ":9090", 45
			c["requesters"].([]any)[0].(map[string]any)["groupsClaim"] = "teams"
			c["approverLogin"].(map[string]any)["groupsClaim"] = "roles"
			c["issuedCredentials"].(map[string]any)["caFile"] = "/custom/ca.crt"
		}},
		{name: "namespace required outside pod", err: "POD_NAMESPACE"},
		{name: "grant namespace must be separate", env: "escalation-grants", err: "separate"},
		{name: "requester audience remains explicit", env: "auth-system", edit: func(c map[string]any) {
			delete(c["requesters"].([]any)[0].(map[string]any), "audience")
		}, err: "explicit audience"},
		{name: "credential audience remains explicit", env: "auth-system", edit: func(c map[string]any) {
			delete(c["issuedCredentials"].(map[string]any), "audience")
		}, err: "issuedCredentials.audience"},
		{name: "role scope remains explicit", env: "auth-system", edit: func(c map[string]any) {
			delete(c["profiles"].([]any)[0].(map[string]any), "cluster")
		}, err: "namespace profiles require namespaces"},
		{name: "approvers remain explicit", env: "auth-system", edit: func(c map[string]any) {
			delete(c["profiles"].([]any)[0].(map[string]any), "approverGroups")
		}, err: "invalid profile"},
		{name: "default timing budget enforced", env: "auth-system", edit: func(c map[string]any) {
			c["profiles"].([]any)[0].(map[string]any)["maxDuration"] = "11m30s"
		}, err: "maxDuration"},
		{name: "unknown fields rejected", env: "auth-system", edit: func(c map[string]any) {
			c["issuedCredentials"].(map[string]any)["audence"] = "typo"
		}, err: "audence"},
		{name: "legacy fields rejected", env: "auth-system", edit: func(c map[string]any) {
			c["audience"] = "old-top-level-key"
		}, err: "audience"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("POD_NAMESPACE", tc.env)
			var input map[string]any
			if err := yaml.Unmarshal([]byte(minimal), &input); err != nil {
				t.Fatal(err)
			}
			if tc.edit != nil {
				tc.edit(input)
			}
			b, err := yaml.Marshal(input)
			if err != nil {
				t.Fatal(err)
			}
			path := filepath.Join(t.TempDir(), "config.yaml")
			if err := os.WriteFile(path, b, 0600); err != nil {
				t.Fatal(err)
			}
			c, err := loadConfig(path)
			if tc.err != "" {
				if err == nil || !strings.Contains(err.Error(), tc.err) {
					t.Fatalf("expected %q error, got %v", tc.err, err)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if c.BaseURL != "https://access.example.org" || c.Requesters[0].Audience != "broker-audience" || c.Requesters[0].RequiredClaims["project"] != "photos" || c.IssuedCredentials.Audience != "cluster-audience" || c.IssuedCredentials.Server != "https://127.0.0.1:6443" || c.IssuedCredentials.TLSName != "private-api.example.org" || c.Profiles[0].ApproverGroups[0] != "storage-approvers" {
				t.Fatal("explicit trust, access or connection settings changed")
			}
			if tc.edit == nil {
				if c.Namespace != "auth-system" || c.GrantNamespace != "escalation-grants" || c.Listen != ":8080" || c.budget() != 90*time.Second || c.IssuedCredentials.CAFile != "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" || c.Requesters[0].GroupsClaim != "groups" || c.ApproverLogin.GroupsClaim != "groups" {
					t.Fatal("incorrect runtime defaults")
				}
			} else if c.Namespace != "broker" || c.GrantNamespace != "temporary-grants" || c.Listen != ":9090" || c.budget() != 105*time.Second || c.IssuedCredentials.CAFile != "/custom/ca.crt" || c.Requesters[0].GroupsClaim != "teams" || c.ApproverLogin.GroupsClaim != "roles" {
				t.Fatal("explicit runtime settings were overwritten")
			}
		})
	}
}
