package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/url"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	authv1 "k8s.io/api/authentication/v1"
	core "k8s.io/api/core/v1"
	rbac "k8s.io/api/rbac/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
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
	if os.Getenv("ESCALATION_TEST_SEED_LEGACY") == "1" {
		p.Role = Role{Kind: "ClusterRole", Name: "escalation-observe"}
		p.Cluster, p.Namespaces = true, nil
		uid, rules, e := a.role(ctx, *p, "")
		if e != nil {
			t.Fatal(e)
		}
		r, e := a.store.create(ctx, &Request{TypeMeta: metav1.TypeMeta{APIVersion: group + "/v1alpha1", Kind: "AccessRequest"}, ObjectMeta: metav1.ObjectMeta{Name: "legacy-null", Namespace: "escalation"}, Spec: Spec{Requester: Identity{Issuer: "legacy", Subject: "thread"}, Profile: *p, DurationSeconds: 720, Reason: "legacy snapshot", PendingUntil: time.Now().Add(time.Hour), RoleUID: uid, Rules: rules, ScopeHash: "legacy-scope", IdempotencyHash: "legacy-key"}})
		if e != nil {
			t.Fatal(e)
		}
		r.Status.Phase = "pending"
		if _, e = a.store.status(ctx, r); !apierrors.IsInvalid(e) {
			t.Fatalf("old schema did not reproduce null status failure: %v", e)
		}
		r.Finalizers = []string{finalizer}
		if _, e = a.store.update(ctx, r); !apierrors.IsInvalid(e) {
			t.Fatalf("old schema did not reproduce null finalizer failure: %v", e)
		}
		r.Name, r.ResourceVersion, r.UID = "legacy-expired", "", ""
		r.Status = Status{}
		r.Spec.PendingUntil = time.Now().Add(-time.Hour)
		if _, e = a.store.create(ctx, r); e != nil {
			t.Fatal(e)
		}
		return
	}
	t.Run("legacy-expired-cleanup", func(t *testing.T) {
		r, e := a.store.get(ctx, "legacy-expired")
		if apierrors.IsNotFound(e) {
			t.Skip("run test/e2e.sh to seed the old-schema snapshot")
		}
		if e != nil {
			t.Fatal(e)
		}
		before := digest(r.Spec)
		if e = a.reconcile(ctx, r); e != nil {
			t.Fatal(e)
		}
		r, e = a.store.get(ctx, r.Name)
		if e != nil {
			t.Fatal(e)
		}
		if r.Status.Phase != "expired" || len(r.Finalizers) != 0 || digest(r.Spec) != before {
			t.Fatalf("expired snapshot not recovered without mutation: %+v", r)
		}
		if e = a.store.client.Delete(ctx, r.Name, metav1.DeleteOptions{}); e != nil {
			t.Fatal(e)
		}
	})
	for _, tc := range []struct {
		name       string
		namespaces []string
	}{{"omitted", nil}, {"empty", []string{}}, {"legacy", nil}} {
		t.Run("cluster-"+tc.name, func(t *testing.T) {
			profile := *p
			defer func() { *p = profile }()
			p.Role = Role{Kind: "ClusterRole", Name: "escalation-observe"}
			p.Cluster, p.Namespaces = true, tc.namespaces
			var r *Request
			var e error
			if tc.name == "legacy" {
				r, e = a.store.get(ctx, "legacy-null")
				if apierrors.IsNotFound(e) {
					t.Skip("run test/e2e.sh to seed the old-schema snapshot")
				}
				if e == nil {
					*p = r.Spec.Profile
					p.Namespaces = []string{}
				}
			} else {
				r, e = a.create(ctx, Identity{Issuer: f.issuer.server.URL, Subject: "cluster-thread"}, createInput{p.Name, "", "12m", "cluster scope test"}, tc.name+time.Now().Format(time.RFC3339Nano))
			}
			if e != nil {
				t.Fatal(e)
			}
			t.Cleanup(func() {
				_ = a.store.client.Delete(ctx, r.Name, metav1.DeleteOptions{})
				if current, err := a.store.get(ctx, r.Name); err == nil {
					_ = a.reconcile(ctx, current)
				}
			})
			before, e := a.store.client.Get(ctx, r.Name, metav1.GetOptions{})
			if e != nil {
				t.Fatal(e)
			}
			assertImmutableSpec(t, ctx, a.store, before)
			if tc.name == "empty" {
				// raw snapshots retain optional empty arrays that go's omitempty drops.
				for _, rules := range []any{nil, []any{}} {
					fixture := before.DeepCopy()
					fixture.SetName("")
					fixture.SetGenerateName("immutable-presence-")
					fixture.SetUID("")
					fixture.SetResourceVersion("")
					unstructured.RemoveNestedField(fixture.Object, "status")
					_ = unstructured.SetNestedField(fixture.Object, []any{}, "spec", "profile", "requesterGroups")
					_ = unstructured.SetNestedField(fixture.Object, rules, "spec", "rules")
					fixture, e = a.store.client.Create(ctx, fixture, metav1.CreateOptions{})
					if e != nil {
						t.Fatal(e)
					}
					assertImmutableSpec(t, ctx, a.store, fixture)
					if e = a.store.client.Delete(ctx, fixture.GetName(), metav1.DeleteOptions{}); e != nil {
						t.Fatal(e)
					}
				}
			}
			r, e = a.decide(ctx, Identity{Issuer: "human", Subject: "reviewer", Groups: []string{"operators"}, Human: true}, r, decisionInput{r.ResourceVersion, r.Spec.ScopeHash, "approve"})
			if e != nil {
				t.Fatal(e)
			}
			if r.Status.Phase != "ready" {
				t.Fatalf("grant not ready: %+v", r.Status)
			}
			credential, e := a.issue(ctx, r)
			if e != nil {
				t.Fatal(e)
			}
			grantConfig := &rest.Config{Host: admin.Host, BearerToken: credential.Token, TLSClientConfig: rest.TLSClientConfig{CAData: admin.CAData, CAFile: admin.CAFile, Insecure: admin.Insecure}, Timeout: 10 * time.Second}
			grant, e := kubernetes.NewForConfig(grantConfig)
			if e != nil {
				t.Fatal(e)
			}
			if _, e = grant.CoreV1().Pods("").List(ctx, metav1.ListOptions{}); e != nil {
				t.Fatalf("cluster read permission absent: %v", e)
			}
			if _, e = grant.CoreV1().Secrets("default").List(ctx, metav1.ListOptions{}); !apierrors.IsForbidden(e) {
				t.Fatalf("cluster grant can read secrets: %v", e)
			}
			r, e = a.revoke(ctx, r.Spec.Requester, r)
			if e != nil {
				t.Fatal(e)
			}
			after, e := a.store.client.Get(ctx, r.Name, metav1.GetOptions{})
			if e != nil {
				t.Fatal(e)
			}
			if !reflect.DeepEqual(before.Object["spec"], after.Object["spec"]) {
				t.Fatal("lifecycle rewrote immutable snapshot")
			}
			if len(after.GetFinalizers()) != 0 {
				t.Fatal("finalizer not removed")
			}
			if _, e = client.RbacV1().ClusterRoleBindings().Get(ctx, r.grantName(), metav1.GetOptions{}); !apierrors.IsNotFound(e) {
				t.Fatalf("binding cleanup incomplete: %v", e)
			}
			if _, e = client.CoreV1().ServiceAccounts("escalation-grants").Get(ctx, r.grantName(), metav1.GetOptions{}); !apierrors.IsNotFound(e) {
				t.Fatalf("account cleanup incomplete: %v", e)
			}
		})
	}
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
	uRequest, err := a.store.client.Get(ctx, r.Name, metav1.GetOptions{})
	if err != nil {
		t.Fatal(err)
	}
	assertImmutableSpec(t, ctx, a.store, uRequest)
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

// mutate each serialized field independently, without recomputing related hashes.
// this catches a missing comparison even when another field normally changes too.
func assertImmutableSpec(t *testing.T, ctx context.Context, store *Store, original *unstructured.Unstructured) {
	t.Helper()
	mutations := map[string]any{
		"requester.issuer": "different", "requester.subject": "different", "requester.groups": []any{"different"},
		"namespace": "different", "durationSeconds": int64(1), "reason": "different",
		"pendingUntil": "2099-01-01T00:00:00Z", "roleUID": "different",
		"rules": []any{}, "scopeHash": "different", "idempotencyHash": "different",
		"profile.name": "different", "profile.role.name": "different",
		"profile.cluster":          !original.Object["spec"].(map[string]any)["profile"].(map[string]any)["cluster"].(bool),
		"profile.requesterIssuers": []any{"different"}, "profile.requesterGroups": []any{},
		"profile.approverGroups": []any{"different"}, "profile.maxDuration": "1m", "profile.pendingDuration": "1m",
	}
	kind, _, _ := unstructured.NestedString(original.Object, "spec", "profile", "role", "kind")
	if kind == "Role" {
		mutations["profile.role.kind"] = "ClusterRole"
	} else {
		mutations["profile.role.kind"] = "Role"
	}
	rules, _, _ := unstructured.NestedSlice(original.Object, "spec", "rules")
	if len(rules) == 0 {
		if rules == nil {
			mutations["rules"] = []any{}
		} else {
			mutations["rules"] = nil
		}
	}
	_, present, _ := unstructured.NestedSlice(original.Object, "spec", "profile", "requesterGroups")
	if present {
		delete(mutations, "profile.requesterGroups")
	}
	ns, _, _ := unstructured.NestedSlice(original.Object, "spec", "profile", "namespaces")
	if ns == nil {
		mutations["profile.namespaces"] = []any{}
	} else {
		mutations["profile.namespaces"] = nil
	}
	for field, value := range mutations {
		t.Run("immutable-"+field, func(t *testing.T) {
			changed := original.DeepCopy()
			path := append([]string{"spec"}, strings.Split(field, ".")...)
			if err := unstructured.SetNestedField(changed.Object, value, path...); err != nil {
				t.Fatal(err)
			}
			if _, err := store.client.Update(ctx, changed, metav1.UpdateOptions{}); !apierrors.IsInvalid(err) || !strings.Contains(err.Error(), "spec is immutable") {
				t.Fatalf("mutation accepted: %v", err)
			}
		})
	}
	if present {
		t.Run("immutable-requesterGroups-presence", func(t *testing.T) {
			changed := original.DeepCopy()
			unstructured.RemoveNestedField(changed.Object, "spec", "profile", "requesterGroups")
			if _, err := store.client.Update(ctx, changed, metav1.UpdateOptions{}); !apierrors.IsInvalid(err) || !strings.Contains(err.Error(), "spec is immutable") {
				t.Fatalf("optional presence mutation accepted: %v", err)
			}
		})
	}
}
