package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	authv1 "k8s.io/api/authentication/v1"
	rbac "k8s.io/api/rbac/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/types"
	dynamicfake "k8s.io/client-go/dynamic/fake"
	kubefake "k8s.io/client-go/kubernetes/fake"
	ktesting "k8s.io/client-go/testing"
)

type appFixture struct {
	app          *App
	kube         *kubefake.Clientset
	issuer       *authFixture
	now          time.Time
	handler      http.Handler
	token        string
	tokenOffset  time.Duration
	statusOffset time.Duration
}

func newAppFixture(t *testing.T) *appFixture {
	t.Helper()
	f := &appFixture{issuer: newAuthFixture(t), now: time.Now().UTC().Truncate(time.Second)}
	auth := f.issuer.auth(t)
	auth.sessions["reviewer-session"] = authSession{Identity{Issuer: "human", Subject: "reviewer", Groups: []string{"operators"}, Human: true}, time.Now().Add(time.Hour), "csrf-value"}
	role := &rbac.Role{ObjectMeta: metav1.ObjectMeta{Name: "observe", Namespace: "photos", UID: "role-uid"}, Rules: []rbac.PolicyRule{{APIGroups: []string{""}, Resources: []string{"pods"}, Verbs: []string{"get", "list"}}}}
	f.kube = kubefake.NewClientset(role)
	d := dynamicfake.NewSimpleDynamicClientWithCustomListKinds(runtime.NewScheme(), map[schema.GroupVersionResource]string{requests: "AccessRequestList"})
	// Fake clients do not assign API metadata. The fixture supplies only that
	// server behavior; authorization/admission is covered by the real API test.
	serial := 0
	metadata := func(action ktesting.Action) (bool, runtime.Object, error) {
		obj := action.(ktesting.CreateAction).GetObject()
		meta := obj.(metav1.Object)
		serial++
		meta.SetUID(types.UID(fmt.Sprintf("00000000-0000-4000-8000-%012d", serial)))
		meta.SetResourceVersion(fmt.Sprint(serial))
		meta.SetCreationTimestamp(metav1.NewTime(f.now))
		return false, nil, nil
	}
	d.PrependReactor("create", "*", metadata)
	f.kube.PrependReactor("create", "serviceaccounts", metadata)
	f.kube.PrependReactor("create", "rolebindings", metadata)
	// TokenRequest is the public issuance boundary. Its signature is not parsed
	// by the broker; the trusted Kubernetes response supplies the JWT expiration.
	f.kube.PrependReactor("create", "serviceaccounts", func(action ktesting.Action) (bool, runtime.Object, error) {
		if action.GetSubresource() != "token" {
			return false, nil, nil
		}
		in := action.(ktesting.CreateAction).GetObject().(*authv1.TokenRequest)
		exp := f.now.Add(time.Duration(*in.Spec.ExpirationSeconds) * time.Second)
		f.token = "header." + base64.RawURLEncoding.EncodeToString([]byte(fmt.Sprintf(`{"exp":%d}`, exp.Add(f.tokenOffset).Unix()))) + ".signature"
		return true, &authv1.TokenRequest{Status: authv1.TokenRequestStatus{Token: f.token, ExpirationTimestamp: metav1.NewTime(exp.Add(f.statusOffset))}}, nil
	})
	ca := filepath.Join(t.TempDir(), "ca.crt")
	if err := os.WriteFile(ca, []byte("test-ca"), 0600); err != nil {
		t.Fatal(err)
	}
	p := Profile{Name: "observe-v1", Role: Role{Kind: "Role", Name: "observe"}, Namespaces: []string{"photos"}, RequesterIssuers: []string{f.issuer.server.URL}, ApproverGroups: []string{"operators"}, MaxDuration: "1h", PendingDuration: "15m"}
	f.app = &App{config: Config{Namespace: "broker", GrantNamespace: "grants", BaseURL: "https://app.example", IssuedCredentials: IssuedCredentialsConfig{Audience: "kubernetes", Server: "https://api.example", CAFile: ca}, ClockSkewSeconds: 30, Profiles: []Profile{p}}, auth: auth, kube: f.kube, store: newStore(d, "broker"), now: func() time.Time { return f.now }}
	f.handler = f.app.handler()
	return f
}

func (f *appFixture) call(t *testing.T, method, path, body, identity string) *httptest.ResponseRecorder {
	t.Helper()
	r := httptest.NewRequest(method, "https://app.example"+path, strings.NewReader(body))
	if identity == "human" {
		r.AddCookie(&http.Cookie{Name: sessionCookie, Value: "reviewer-session"})
		r.Header.Set("X-CSRF-Token", "csrf-value")
	} else if identity != "" {
		claims := f.issuer.claims()
		claims["sub"] = identity
		r.Header.Set("Authorization", "Bearer "+f.issuer.sign(t, claims))
	}
	r.Header.Set("Idempotency-Key", "stable-request-key")
	r.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	f.handler.ServeHTTP(w, r)
	return w
}

func checkCode(t *testing.T, w *httptest.ResponseRecorder, want int) {
	t.Helper()
	if w.Code != want {
		t.Fatalf("status %d, want %d: %s", w.Code, want, w.Body.String())
	}
}
func (f *appFixture) request(t *testing.T) *Request {
	t.Helper()
	w := f.call(t, "POST", "/v1/requests", `{"profile":"observe-v1","namespace":"photos","duration":"30m","reason":"inspect database storage"}`, "thread-a")
	checkCode(t, w, 202)
	var out struct {
		Request *Request `json:"request"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &out); err != nil {
		t.Fatal(err)
	}
	return out.Request
}
func (f *appFixture) approve(t *testing.T, r *Request) *Request {
	t.Helper()
	body, _ := json.Marshal(decisionInput{r.ResourceVersion, r.Spec.ScopeHash, "approve"})
	w := f.call(t, "POST", "/v1/requests/"+r.Name+"/decision", string(body), "human")
	checkCode(t, w, 202)
	var out Request
	if err := json.Unmarshal(w.Body.Bytes(), &out); err != nil {
		t.Fatal(err)
	}
	if out.Status.Phase != "ready" {
		t.Fatalf("grant not ready: %+v", out.Status)
	}
	return &out
}

func TestAccessLifecycle(t *testing.T) {
	f := newAppFixture(t)
	r := f.request(t)
	again := f.request(t)
	if again.UID != r.UID {
		t.Fatal("idempotent retry created another request")
	}
	base := "/v1/requests/" + r.Name
	checkCode(t, f.call(t, "GET", base, "", "thread-b"), 404)
	checkCode(t, f.call(t, "POST", base+"/credentials", "", "thread-a"), 503)
	body, _ := json.Marshal(decisionInput{r.ResourceVersion, r.Spec.ScopeHash, "approve"})
	checkCode(t, f.call(t, "POST", base+"/decision", string(body), "thread-a"), 403)
	r = f.approve(t, r)
	deadline := *r.Status.Deadline
	checkCode(t, f.call(t, "POST", base+"/decision", string(body), "human"), 409)
	checkCode(t, f.call(t, "POST", base+"/credentials", "", "human"), 403)
	checkCode(t, f.call(t, "POST", base+"/credentials", "", "thread-b"), 404)
	w := f.call(t, "POST", base+"/credentials", "", "thread-a")
	checkCode(t, w, 200)
	var cred Credential
	if err := json.Unmarshal(w.Body.Bytes(), &cred); err != nil {
		t.Fatal(err)
	}
	// 30 minutes less 60 seconds validator leeway and 30 seconds skew.
	if !cred.Expiration.Equal(f.now.Add(1710*time.Second)) || string(cred.CAData) != "test-ca" {
		t.Fatalf("wrong credential metadata: %v", cred.Expiration)
	}
	f.now = f.now.Add(5 * time.Minute)
	w = f.call(t, "POST", base+"/credentials", "", "thread-a")
	checkCode(t, w, 200)
	var retry Credential
	_ = json.Unmarshal(w.Body.Bytes(), &retry)
	if retry.Expiration.After(cred.Expiration) {
		t.Fatal("pickup extended expiry")
	}
	w = f.call(t, "GET", base, "", "thread-a")
	checkCode(t, w, 200)
	if strings.Contains(w.Body.String(), cred.Token) {
		t.Fatal("detail leaked credential")
	}
	f.app.config.Profiles = nil // cleanup must not depend on profile eligibility
	checkCode(t, f.call(t, "POST", base+"/revoke", "", "thread-a"), 202)
	if _, err := f.kube.CoreV1().ServiceAccounts("grants").Get(context.Background(), r.grantName(), metav1.GetOptions{}); !apierrors.IsNotFound(err) {
		t.Fatalf("grant account remains: %v", err)
	}
	if _, err := f.kube.RbacV1().RoleBindings("photos").Get(context.Background(), r.grantName(), metav1.GetOptions{}); !apierrors.IsNotFound(err) {
		t.Fatalf("grant binding remains: %v", err)
	}
	checkCode(t, f.call(t, "POST", base+"/credentials", "", "thread-a"), 503)
	current, err := f.app.store.get(context.Background(), r.Name)
	if err != nil {
		t.Fatal(err)
	}
	if !current.Status.Deadline.Equal(deadline) || current.Status.Message != "cleanup complete" {
		t.Fatalf("bad final state: %+v", current.Status)
	}
}

func TestBrowserApprovalAndCSRF(t *testing.T) {
	f := newAppFixture(t)
	r := f.request(t)
	path := "/requests/" + r.Name
	w := f.call(t, "GET", path, "", "")
	checkCode(t, w, 303)
	w = f.call(t, "GET", path, "", "human")
	checkCode(t, w, 200)
	if w.Header().Get("Referrer-Policy") != "same-origin" {
		t.Fatal("browser forms need a same-origin Origin header for csrf validation")
	}
	for _, want := range []string{"photos", "inspect database storage", "role permissions", "approve access", "1800 seconds"} {
		if !strings.Contains(w.Body.String(), want) {
			t.Fatalf("page missing %q", want)
		}
	}
	form := url.Values{"csrf": {"csrf-value"}, "version": {r.ResourceVersion}, "scopeHash": {r.Spec.ScopeHash}, "decision": {"approve"}}
	post := func(body string) *httptest.ResponseRecorder {
		req := httptest.NewRequest("POST", "https://app.example"+path, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		req.AddCookie(&http.Cookie{Name: sessionCookie, Value: "reviewer-session"})
		w := httptest.NewRecorder()
		f.handler.ServeHTTP(w, req)
		return w
	}
	checkCode(t, post(strings.Replace(form.Encode(), "csrf-value", "wrong", 1)), 403)
	checkCode(t, post(form.Encode()+"&csrf=csrf-value"), 403)
	checkCode(t, post(form.Encode()), 303)
	w = f.call(t, "GET", path, "", "human")
	checkCode(t, w, 200)
	if strings.Contains(w.Body.String(), "approve access") || !strings.Contains(w.Body.String(), "ready") {
		t.Fatal("approval page did not reflect decision")
	}
}

func TestDeletedGrantNeverReactivated(t *testing.T) {
	for _, object := range []string{"account", "binding", "account-before-status", "binding-before-status"} {
		t.Run(object, func(t *testing.T) {
			f := newAppFixture(t)
			r := f.approve(t, f.request(t))
			ctx := context.Background()
			if strings.HasPrefix(object, "account") {
				_ = f.kube.CoreV1().ServiceAccounts("grants").Delete(ctx, r.grantName(), metav1.DeleteOptions{})
			} else {
				_ = f.kube.RbacV1().RoleBindings("photos").Delete(ctx, r.grantName(), metav1.DeleteOptions{})
			}
			if object == "account-before-status" {
				r.Status.AccountUID = ""
				r.Status.BindingUID = ""
				r.Status.Phase = "provisioning"
			}
			if object == "binding-before-status" {
				r.Status.BindingUID = ""
				r.Status.Phase = "binding"
			}
			var err error
			r, err = f.app.store.status(ctx, r)
			if err != nil {
				t.Fatal(err)
			}
			// A restarted broker has only the durable request and Kubernetes objects.
			f.app.mu.Lock()
			err = f.app.reconcile(ctx, r)
			f.app.mu.Unlock()
			if err != nil {
				t.Fatal(err)
			}
			r, err = f.app.store.get(ctx, r.Name)
			if err != nil {
				t.Fatal(err)
			}
			if r.Status.Phase != "failed" {
				t.Fatalf("grant reactivated: %+v", r.Status)
			}
			if _, err = f.kube.CoreV1().ServiceAccounts("grants").Get(ctx, r.grantName(), metav1.GetOptions{}); !apierrors.IsNotFound(err) {
				t.Fatal("account resurrected")
			}
			checkCode(t, f.call(t, "POST", "/v1/requests/"+r.Name+"/credentials", "", "thread-a"), 503)
		})
	}
}

func TestTokenBoundsAndPolicyDrift(t *testing.T) {
	for _, scenario := range []string{"jwt-too-long", "status-too-long", "late-pickup", "role-drift", "namespace"} {
		t.Run(scenario, func(t *testing.T) {
			f := newAppFixture(t)
			if scenario == "namespace" {
				checkCode(t, f.call(t, "POST", "/v1/requests", `{"profile":"observe-v1","namespace":"grants","duration":"30m","reason":"no"}`, "thread-a"), 403)
				return
			}
			r := f.approve(t, f.request(t))
			ctx := context.Background()
			switch scenario {
			case "jwt-too-long":
				f.tokenOffset = time.Second
			case "status-too-long":
				f.statusOffset = time.Second
			case "late-pickup":
				f.now = f.now.Add(1111 * time.Second)
			case "role-drift":
				role, _ := f.kube.RbacV1().Roles("photos").Get(ctx, "observe", metav1.GetOptions{})
				role.Rules[0].Verbs = append(role.Rules[0].Verbs, "watch")
				_, _ = f.kube.RbacV1().Roles("photos").Update(ctx, role, metav1.UpdateOptions{})
			}
			w := f.call(t, "POST", "/v1/requests/"+r.Name+"/credentials", "", "thread-a")
			checkCode(t, w, 503)
			if strings.Contains(w.Body.String(), "signature") {
				t.Fatal("rejected token leaked")
			}
			if scenario == "jwt-too-long" || scenario == "status-too-long" {
				if _, err := f.kube.CoreV1().ServiceAccounts("grants").Get(ctx, r.grantName(), metav1.GetOptions{}); !apierrors.IsNotFound(err) {
					t.Fatal("oversized token not revoked")
				}
			}
		})
	}
}

func TestExpiryRecoveryAndCleanupFailure(t *testing.T) {
	f := newAppFixture(t)
	r := f.approve(t, f.request(t))
	f.now = f.now.Add(31 * time.Minute)
	ctx := context.Background()
	f.kube.PrependReactor("delete", "serviceaccounts", func(action ktesting.Action) (bool, runtime.Object, error) {
		return true, nil, fmt.Errorf("api unavailable")
	})
	if err := f.app.reconcile(ctx, r); err == nil {
		t.Fatal("cleanup outage reported success")
	}
	r, _ = f.app.store.get(ctx, r.Name)
	if r.Status.Message == "cleanup complete" || len(r.Finalizers) == 0 {
		t.Fatal("cleanup falsely confirmed")
	}
	f.kube.ReactionChain = f.kube.ReactionChain[1:]
	if err := f.app.reconcile(ctx, r); err != nil {
		t.Fatal(err)
	}
	r, _ = f.app.store.get(ctx, r.Name)
	if r.Status.Phase != "expired" || r.Status.Message != "cleanup complete" || len(r.Finalizers) != 0 {
		t.Fatalf("recovery failed: %+v", r)
	}
}
