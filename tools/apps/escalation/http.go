package main

import (
	"context"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"html/template"
	"io"
	"log/slog"
	"net/http"
	"os"
	"slices"
	"strings"
	"time"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

//go:embed page.html
var pageHTML string
var pageTemplate = template.Must(template.New("page").Funcs(template.FuncMap{"json": func(v any) string { b, _ := json.MarshalIndent(v, "", "  "); return string(b) }, "time": func(t *time.Time) string {
	if t == nil {
		return "not approved"
	}
	return t.UTC().Format(time.RFC3339)
}}).Parse(pageHTML))

type createInput struct {
	Profile   string `json:"profile"`
	Namespace string `json:"namespace"`
	Duration  string `json:"duration"`
	Reason    string `json:"reason"`
}
type decisionInput struct {
	Version   string `json:"version"`
	ScopeHash string `json:"scopeHash"`
	Decision  string `json:"decision"`
}
type responseError struct {
	code    int
	message string
}

type pageData struct {
	Request     *Request
	Items       []*Request
	CSRF        string
	CanApprove  bool
	CanRevoke   bool
	CanWithdraw bool
	Next        string
	Error       string
	Reload      string
}

func (e responseError) Error() string { return e.message }

type rateWindow struct {
	until time.Time
	count int
}

// Called under the app mutex. Bounded state also limits distinct active identities.
func (a *App) allowRequest(i Identity) bool {
	if a.rate == nil {
		a.rate = make(map[string]rateWindow)
	}
	now := a.now()
	for k, v := range a.rate {
		if !now.Before(v.until) {
			delete(a.rate, k)
		}
	}
	key := digest([]string{i.Issuer, i.Subject})
	v, exists := a.rate[key]
	if !exists {
		if len(a.rate) >= 1024 {
			return false
		}
		v.until = now.Add(time.Minute)
	}
	if v.count >= 60 {
		return false
	}
	v.count++
	a.rate[key] = v
	return true
}

func problem(code int, msg string) error { return responseError{code, msg} }
func reply(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}
func fail(w http.ResponseWriter, r *http.Request, err error) {
	code := http.StatusServiceUnavailable
	msg := "operation unavailable; reload to check whether it completed"
	var e responseError
	if errors.As(err, &e) {
		code = e.code
		msg = e.message
	} else if apierrors.IsConflict(err) || apierrors.IsAlreadyExists(err) {
		code = 409
		msg = "state changed; reload before retrying"
	} else if apierrors.IsNotFound(err) {
		code = 404
		msg = "request not found"
	}
	if code >= 500 {
		slog.Error("operation failed", "method", r.Method, "path", r.URL.Path, "error", err)
	}
	if strings.HasPrefix(r.URL.Path, "/v1/") {
		reply(w, code, map[string]string{"error": msg})
		return
	}
	reload := "/"
	if strings.HasPrefix(r.URL.Path, "/requests/") {
		reload = r.URL.Path
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(code)
	_ = pageTemplate.Execute(w, pageData{Error: msg, Reload: reload})
}

func parseJSON(r *http.Request, v any) error {
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if e := d.Decode(v); e != nil {
		return problem(400, "invalid json request")
	}
	if e := d.Decode(&struct{}{}); e != io.EOF {
		return problem(400, "request must contain one json object")
	}
	return nil
}

func (a *App) allowedRead(i Identity, r *Request) bool {
	return sameIdentity(i, r.Spec.Requester) || r.Spec.Profile.approver(i)
}

func (a *App) create(ctx context.Context, i Identity, in createInput, key string) (*Request, error) {
	idx := slices.IndexFunc(a.config.Profiles, func(p Profile) bool { return p.Name == in.Profile })
	if idx < 0 {
		return nil, problem(403, "profile not eligible")
	}
	p := a.config.Profiles[idx]
	if !p.requester(i) || !p.permits(in.Namespace) {
		return nil, problem(403, "profile or scope not eligible")
	}
	d, e := time.ParseDuration(in.Duration)
	max, _ := time.ParseDuration(p.MaxDuration)
	if e != nil || d > max || d < 10*time.Minute+a.config.budget()+time.Second || d%time.Second != 0 {
		return nil, problem(400, "duration must fit profile and token timing bounds")
	}
	if len(strings.TrimSpace(in.Reason)) == 0 || len(in.Reason) > 1024 {
		return nil, problem(400, "reason must be between 1 and 1024 bytes")
	}
	if len(key) < 8 || len(key) > 128 {
		return nil, problem(400, "Idempotency-Key must be between 8 and 128 bytes")
	}
	id := "request-" + digest([]string{i.Issuer, i.Subject, key})[:40]
	bodyHash := digest(in)
	if existing, e := a.store.get(ctx, id); e == nil {
		if !sameIdentity(i, existing.Spec.Requester) || existing.Spec.IdempotencyHash != bodyHash {
			return nil, problem(409, "idempotency key has a different request")
		}
		return existing, nil
	} else if !apierrors.IsNotFound(e) {
		return nil, e
	}
	uid, rules, e := a.role(ctx, p, in.Namespace)
	if e != nil {
		return nil, e
	}
	pending, _ := time.ParseDuration(p.PendingDuration)
	// Only verified, necessary audit identity is persisted; Claims never contains
	// credentials, but is deliberately not part of the durable record.
	i.Claims = nil
	i.Human = false
	spec := Spec{Requester: i, Profile: p, Namespace: in.Namespace, DurationSeconds: int64(d / time.Second), Reason: in.Reason, PendingUntil: a.now().Add(pending), RoleUID: uid, Rules: rules, IdempotencyHash: bodyHash}
	spec.ScopeHash = digest(spec)
	r := &Request{TypeMeta: metav1.TypeMeta{APIVersion: group + "/v1alpha1", Kind: "AccessRequest"}, ObjectMeta: metav1.ObjectMeta{Name: id, Namespace: a.config.Namespace}, Spec: spec}
	r, e = a.store.create(ctx, r)
	if e == nil {
		a.audit("access requested", r, i)
	}
	return r, e
}

func (a *App) decide(ctx context.Context, i Identity, r *Request, in decisionInput) (*Request, error) {
	if !r.Spec.Profile.approver(i) || sameIdentity(i, r.Spec.Requester) {
		return nil, problem(403, "human approval not eligible")
	}
	if r.ResourceVersion != in.Version || r.Spec.ScopeHash != in.ScopeHash || r.Status.Phase != "" || r.terminal(a.now()) {
		return nil, problem(409, "request changed or is no longer pending")
	}
	if in.Decision != "approve" && in.Decision != "deny" {
		return nil, problem(400, "decision must be approve or deny")
	}
	i.Claims = nil
	r.Status.Actor = &i
	if in.Decision == "deny" {
		r.Status.Phase = "denied"
	} else {
		if e := a.unchanged(ctx, r); e != nil {
			return nil, e
		}
		deadline := a.now().Add(time.Duration(r.Spec.DurationSeconds) * time.Second)
		r.Status.Deadline = &deadline
		r.Status.Phase = "approved"
		r.Status.Message = "approval saved; preparing access"
	}
	r, e := a.store.status(ctx, r)
	if e != nil {
		return nil, e
	}
	a.audit("access "+in.Decision, r, i)
	// The persisted decision survives temporary provisioning failure; the loop
	// retries it. Never report credential readiness before reconciliation confirms it.
	if err := a.reconcile(ctx, r); err != nil {
		slog.Error("approved grant reconciliation failed", "request", r.Name, "error", err)
	}
	return a.store.get(ctx, r.Name)
}

func (a *App) revoke(ctx context.Context, i Identity, r *Request) (*Request, error) {
	if !a.allowedRead(i, r) {
		return nil, problem(404, "request not found")
	}
	if r.terminal(a.now()) {
		return r, nil
	}
	r.Status.Phase = "revoked"
	r.Status.Message = "revocation pending"
	updated, e := a.store.status(ctx, r)
	if e != nil {
		return nil, e
	}
	a.audit("access revoked", updated, i)
	_ = a.reconcile(ctx, updated)
	return a.store.get(ctx, r.Name)
}

func (a *App) handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(200) })
	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, r *http.Request) {
		a.mu.Lock()
		defer a.mu.Unlock()
		if a.lastReconcile.IsZero() || a.now().Sub(a.lastReconcile) > time.Minute {
			http.Error(w, "reconciliation unavailable", 503)
			return
		}
		w.WriteHeader(200)
	})
	mux.HandleFunc("GET /metrics", func(w http.ResponseWriter, r *http.Request) {
		a.mu.Lock()
		defer a.mu.Unlock()
		w.Header().Set("Content-Type", "text/plain; version=0.0.4")
		fmt.Fprintf(w, "escalation_reconcile_errors_total %d\nescalation_overdue_cleanup %d\n", a.reconcileErrors, a.overdue)
	})
	mux.HandleFunc("GET /login", a.auth.Login)
	mux.HandleFunc("GET /callback", a.auth.Callback)
	mux.HandleFunc("POST /logout", func(w http.ResponseWriter, r *http.Request) {
		if !a.auth.CheckCSRF(r) {
			fail(w, r, problem(403, "invalid csrf token; reload and try again"))
			return
		}
		a.auth.Logout(w, r)
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		i, e := a.auth.Authenticate(r)
		if e != nil {
			if (r.URL.Path == "/" || strings.HasPrefix(r.URL.Path, "/requests/")) && r.Method == "GET" && len(r.Header.Values("Authorization")) == 0 {
				http.Redirect(w, r, "/login", 303)
			} else {
				fail(w, r, problem(401, "authentication required"))
			}
			return
		}
		if r.Method != "GET" && r.Method != "POST" {
			fail(w, r, problem(405, "method not allowed"))
			return
		}
		if r.Method == "POST" && i.Human && !a.auth.CheckCSRF(r) {
			fail(w, r, problem(403, "invalid csrf token; reload and try again"))
			return
		}
		a.mu.Lock()
		defer a.mu.Unlock()
		if !a.allowRequest(i) {
			w.Header().Set("Retry-After", "60")
			fail(w, r, problem(429, "identity rate limit exceeded; retry in one minute"))
			return
		}
		if strings.HasPrefix(r.URL.Path, "/v1/") {
			a.api(w, r, i)
			return
		}
		a.page(w, r, i)
	})
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Referrer-Policy", "same-origin")
		w.Header().Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'; base-uri 'none'")
		r.Body = http.MaxBytesReader(w, r.Body, 16*1024)
		ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
		defer cancel()
		mux.ServeHTTP(w, r.WithContext(ctx))
	})
}

func (a *App) api(w http.ResponseWriter, r *http.Request, i Identity) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/")
	if path == "profiles" && r.Method == "GET" {
		out := []Profile{}
		for _, p := range a.config.Profiles {
			if p.requester(i) || p.approver(i) {
				out = append(out, p)
			}
		}
		reply(w, 200, out)
		return
	}
	if path == "requests" {
		if r.Method == "POST" {
			var in createInput
			if e := parseJSON(r, &in); e != nil {
				fail(w, r, e)
				return
			}
			req, e := a.create(r.Context(), i, in, r.Header.Get("Idempotency-Key"))
			if e != nil {
				fail(w, r, e)
				return
			}
			reply(w, 202, map[string]any{"request": req, "approvalURL": a.config.BaseURL + "/requests/" + req.Name})
			return
		}
		rs, next, e := a.store.list(r.Context(), 100, r.URL.Query().Get("continue"))
		if e != nil {
			fail(w, r, e)
			return
		}
		out := []*Request{}
		for _, req := range rs {
			if a.allowedRead(i, req) {
				out = append(out, req)
			}
		}
		reply(w, 200, map[string]any{"items": out, "continue": next})
		return
	}
	parts := strings.Split(path, "/")
	if len(parts) < 2 || len(parts) > 3 || parts[0] != "requests" {
		fail(w, r, problem(404, "not found"))
		return
	}
	req, e := a.store.get(r.Context(), parts[1])
	if e != nil {
		fail(w, r, e)
		return
	}
	if !a.allowedRead(i, req) {
		fail(w, r, problem(404, "request not found"))
		return
	}
	if len(parts) == 2 && r.Method == "GET" {
		reply(w, 200, req)
		return
	}
	if len(parts) != 3 || r.Method != "POST" {
		fail(w, r, problem(405, "method not allowed"))
		return
	}
	switch parts[2] {
	case "decision":
		var in decisionInput
		if e = parseJSON(r, &in); e == nil {
			req, e = a.decide(r.Context(), i, req, in)
		}
	case "revoke":
		req, e = a.revoke(r.Context(), i, req)
	case "credentials":
		if !sameIdentity(i, req.Spec.Requester) || i.Human {
			fail(w, r, problem(403, "requester bearer authentication required"))
			return
		}
		var cred Credential
		cred, e = a.issue(r.Context(), req)
		if e == nil {
			cred.CAData, e = os.ReadFile(a.config.IssuedCredentials.CAFile)
		}
		if e != nil {
			fail(w, r, e)
			return
		}
		reply(w, 200, cred)
		return
	default:
		e = problem(404, "not found")
	}
	if e != nil {
		fail(w, r, e)
		return
	}
	reply(w, 202, req)
}

func (a *App) page(w http.ResponseWriter, r *http.Request, i Identity) {
	if !i.Human {
		fail(w, r, problem(403, "human browser login required"))
		return
	}
	var req *Request
	var rs []*Request
	var err error
	var next string
	if r.URL.Path == "/" && r.Method == "GET" {
		var all []*Request
		all, next, err = a.store.list(r.Context(), 100, r.URL.Query().Get("continue"))
		for _, item := range all {
			if a.allowedRead(i, item) {
				rs = append(rs, item)
			}
		}
	} else if strings.HasPrefix(r.URL.Path, "/requests/") {
		id := strings.TrimPrefix(r.URL.Path, "/requests/")
		if strings.Contains(id, "/") {
			fail(w, r, problem(404, "not found"))
			return
		}
		req, err = a.store.get(r.Context(), id)
		if err == nil && !a.allowedRead(i, req) {
			err = problem(404, "request not found")
		}
		if err == nil && r.Method == "POST" {
			if r.FormValue("decision") == "revoke" {
				req, err = a.revoke(r.Context(), i, req)
			} else {
				req, err = a.decide(r.Context(), i, req, decisionInput{Version: r.FormValue("version"), ScopeHash: r.FormValue("scopeHash"), Decision: r.FormValue("decision")})
			}
			if err == nil {
				http.Redirect(w, r, r.URL.Path, 303)
				return
			}
		}
	} else {
		err = problem(404, "not found")
	}
	if err != nil {
		fail(w, r, err)
		return
	}
	canApprove := req != nil && req.Spec.Profile.approver(i) && !sameIdentity(i, req.Spec.Requester) && req.Status.Phase == "" && !req.terminal(a.now())
	canRevoke := req != nil && req.Status.Deadline != nil && !req.terminal(a.now())
	canWithdraw := req != nil && sameIdentity(i, req.Spec.Requester) && req.Status.Phase == "" && !req.terminal(a.now())
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_ = pageTemplate.Execute(w, pageData{Request: req, Items: rs, CSRF: a.auth.CSRF(r), CanApprove: canApprove, CanRevoke: canRevoke, CanWithdraw: canWithdraw, Next: next})
}
