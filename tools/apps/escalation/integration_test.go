package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	authv1 "k8s.io/api/authentication/v1"
	core "k8s.io/api/core/v1"
	rbac "k8s.io/api/rbac/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

// This opt-in test writes only to an explicitly supplied, disposable loopback
// API. test/e2e.sh provisions the chart and roles before running it.
func TestKubernetesGrant(t *testing.T) {
	path := os.Getenv("ESCALATION_TEST_KUBECONFIG")
	if path == "" {
		t.Skip("set ESCALATION_TEST_KUBECONFIG for a disposable API")
	}
	admin, err := clientcmd.BuildConfigFromFlags("", path)
	if err != nil {
		t.Fatal(err)
	}
	u, err := url.Parse(admin.Host)
	if err != nil || (u.Hostname() != "127.0.0.1" && u.Hostname() != "localhost") {
		t.Fatal("refusing non-loopback test cluster")
	}
	ctx := context.Background()
	admin.Timeout = 10 * time.Second
	k, err := kubernetes.NewForConfig(admin)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = k.CoreV1().ServiceAccounts("escalation").Get(ctx, "escalation", metav1.GetOptions{}); err != nil {
		t.Fatalf("install the test chart first: %v", err)
	}
	// Impersonation exercises chart RBAC and its server-identity admission rules.
	server := rest.CopyConfig(admin)
	server.Impersonate = rest.ImpersonationConfig{UserName: "system:serviceaccount:escalation:escalation", Groups: []string{"system:serviceaccounts", "system:serviceaccounts:escalation", "system:authenticated"}}
	client, err := kubernetes.NewForConfig(server)
	if err != nil {
		t.Fatal(err)
	}
	d, err := dynamic.NewForConfig(server)
	if err != nil {
		t.Fatal(err)
	}
	f := newAppFixture(t)
	a := f.app
	a.kube = client
	a.store = newStore(d, "escalation")
	a.now = time.Now
	a.config.Namespace = "escalation"
	a.config.GrantNamespace = "escalation-grants"
	a.config.IssuedCredentials.Audience = "https://kubernetes.default.svc"
	a.config.IssuedCredentials.Server = admin.Host
	p := &a.config.Profiles[0]
	p.Role.Name = "escalation-observe"
	p.Namespaces = []string{"default"}
	p.MaxDuration = "30m"
	r, err := a.create(ctx, Identity{Issuer: f.issuer.server.URL, Subject: "integration-thread"}, createInput{p.Name, "default", "12m", "disposable permission and expiry test"}, time.Now().Format(time.RFC3339Nano))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_ = a.store.client.Delete(ctx, r.Name, metav1.DeleteOptions{})
		if current, e := a.store.get(ctx, r.Name); e == nil {
			_ = a.reconcile(ctx, current)
		}
	})
	r, err = a.decide(ctx, Identity{Issuer: "human", Subject: "reviewer", Groups: []string{"operators"}, Human: true}, r, decisionInput{r.ResourceVersion, r.Spec.ScopeHash, "approve"})
	if err != nil {
		t.Fatal(err)
	}
	if r.Status.Phase != "ready" {
		t.Fatalf("grant not ready: %+v", r.Status)
	}
	credential, err := a.issue(ctx, r)
	if err != nil {
		t.Fatal(err)
	}
	if credential.Expiration.Add(90 * time.Second).After(*r.Status.Deadline) {
		t.Fatal("expiration exceeds approved budget")
	}
	grantConfig := &rest.Config{Host: admin.Host, BearerToken: credential.Token, TLSClientConfig: admin.TLSClientConfig, Timeout: 10 * time.Second}
	// Never leak administrator certificate authentication into the grant client.
	grantConfig.CertData = nil
	grantConfig.CertFile = ""
	grantConfig.KeyData = nil
	grantConfig.KeyFile = ""
	grant, err := kubernetes.NewForConfig(grantConfig)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = grant.CoreV1().Pods("default").List(ctx, metav1.ListOptions{}); err != nil {
		t.Fatalf("reviewed read permission absent: %v", err)
	}
	if _, err = grant.CoreV1().Secrets("default").List(ctx, metav1.ListOptions{}); !apierrors.IsForbidden(err) {
		t.Fatalf("grant can read secrets: %v", err)
	}
	if _, err = grant.RbacV1().RoleBindings("default").Create(ctx, &rbac.RoleBinding{ObjectMeta: metav1.ObjectMeta{Name: "should-be-denied"}}, metav1.CreateOptions{}); !apierrors.IsForbidden(err) {
		t.Fatalf("grant can change rbac: %v", err)
	}
	seconds := int64(600)
	tokenRequest := &authv1.TokenRequest{Spec: authv1.TokenRequestSpec{Audiences: []string{a.config.IssuedCredentials.Audience}, ExpirationSeconds: &seconds}}
	if _, err = grant.CoreV1().ServiceAccounts("escalation-grants").CreateToken(ctx, r.grantName(), tokenRequest, metav1.CreateOptions{}); !apierrors.IsForbidden(err) {
		t.Fatalf("grant can mint replacement credentials: %v", err)
	}
	if _, err = client.CoreV1().ServiceAccounts("escalation-grants").Create(ctx, &core.ServiceAccount{ObjectMeta: metav1.ObjectMeta{Name: "unrelated"}}, metav1.CreateOptions{}); err == nil || !strings.Contains(err.Error(), "grant objects require deterministic names") {
		t.Fatalf("server can create unrelated account: %v", err)
	}
	unrelated, err := k.CoreV1().ServiceAccounts("escalation-grants").Create(ctx, &core.ServiceAccount{ObjectMeta: metav1.ObjectMeta{GenerateName: "unrelated-"}}, metav1.CreateOptions{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_ = k.CoreV1().ServiceAccounts("escalation-grants").Delete(ctx, unrelated.Name, metav1.DeleteOptions{})
	})
	if _, err = client.CoreV1().ServiceAccounts("escalation-grants").CreateToken(ctx, unrelated.Name, tokenRequest, metav1.CreateOptions{}); err == nil || !strings.Contains(err.Error(), "token requests must target grant accounts") {
		t.Fatalf("server minted unrelated credential: %v", err)
	}
	if err = client.CoreV1().ServiceAccounts("escalation-grants").Delete(ctx, unrelated.Name, metav1.DeleteOptions{}); err == nil || !strings.Contains(err.Error(), "grant objects require deterministic names") {
		t.Fatalf("server deleted unrelated account: %v", err)
	}
	for _, mutate := range []func(*Request){func(r *Request) { r.Spec.Reason = "tampered" }, func(r *Request) { r.Spec.Rules[0].Verbs = []string{"delete"} }, func(r *Request) { r.Spec.Profile.Role.Name = "other" }} {
		b, _ := json.Marshal(r)
		var changed Request
		_ = json.Unmarshal(b, &changed)
		mutate(&changed)
		if _, err = a.store.update(ctx, &changed); !apierrors.IsInvalid(err) {
			t.Fatalf("spec mutation accepted: %v", err)
		}
	}
	// No broker reconciliation runs while checking expiry. Objects remain, so a
	// denial here comes from Kubernetes JWT validation rather than cleanup.
	if os.Getenv("ESCALATION_TEST_WAIT_EXPIRY") == "1" {
		wait := time.Until(credential.Expiration.Add(61 * time.Second))
		t.Logf("broker offline; waiting %s for native token expiry", wait.Round(time.Second))
		time.Sleep(wait)
		if _, err = grant.CoreV1().Pods("default").List(ctx, metav1.ListOptions{}); !apierrors.IsUnauthorized(err) {
			t.Fatalf("expired grant accepted with broker offline: %v", err)
		}
		if _, err = client.CoreV1().ServiceAccounts("escalation-grants").Get(ctx, r.grantName(), metav1.GetOptions{}); err != nil {
			t.Fatalf("expiry check lost account: %v", err)
		}
	}
	if _, err = a.revoke(ctx, r.Spec.Requester, r); err != nil {
		t.Fatal(err)
	}
	deadline := time.Now().Add(15 * time.Second)
	for {
		_, err = grant.CoreV1().Pods("default").List(ctx, metav1.ListOptions{})
		if apierrors.IsUnauthorized(err) {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("revoked token still accepted: %v", err)
		}
		time.Sleep(200 * time.Millisecond)
	}
	if _, err = client.CoreV1().ServiceAccounts("escalation-grants").Get(ctx, r.grantName(), metav1.GetOptions{}); !apierrors.IsNotFound(err) {
		t.Fatalf("cleanup incomplete: %v", err)
	}
	// A grant token is never a requester credential, regardless of its RBAC.
	req, _ := http.NewRequest("GET", "https://app.example/v1/requests", nil)
	req.Header.Set("Authorization", "Bearer "+credential.Token)
	if _, err = a.auth.Authenticate(req); err == nil {
		t.Fatal("grant token became requester identity")
	}
}
