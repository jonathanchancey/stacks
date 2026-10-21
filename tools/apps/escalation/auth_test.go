package main

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"
)

type authFixture struct {
	server           *httptest.Server
	key              *rsa.PrivateKey
	nonce, challenge string
}

func newAuthFixture(t *testing.T) *authFixture {
	t.Helper()
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	f := &authFixture{key: k}
	f.server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		switch r.URL.Path {
		case "/.well-known/openid-configuration":
			_ = json.NewEncoder(w).Encode(map[string]any{"issuer": f.server.URL, "authorization_endpoint": f.server.URL + "/authorize", "token_endpoint": f.server.URL + "/token", "jwks_uri": f.server.URL + "/keys", "id_token_signing_alg_values_supported": []string{"RS256"}})
		case "/keys":
			_ = json.NewEncoder(w).Encode(map[string]any{"keys": []any{map[string]any{"kty": "RSA", "kid": "test", "alg": "RS256", "use": "sig", "n": base64.RawURLEncoding.EncodeToString(k.N.Bytes()), "e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(k.E)).Bytes())}}})
		case "/token":
			_ = r.ParseForm()
			h := sha256.Sum256([]byte(r.Form.Get("code_verifier")))
			if r.Form.Get("code") != "test-code" || base64.RawURLEncoding.EncodeToString(h[:]) != f.challenge || r.Form.Get("redirect_uri") != "https://app.example/callback" {
				http.Error(w, "invalid exchange", 400)
				return
			}
			c := f.claims()
			c["aud"] = "browser"
			c["nonce"] = f.nonce
			_ = json.NewEncoder(w).Encode(map[string]any{"access_token": "unused", "token_type": "Bearer", "id_token": f.sign(t, c)})
		default:
			http.NotFound(w, r)
		}
	}))
	t.Cleanup(f.server.Close)
	return f
}
func (f *authFixture) claims() map[string]any {
	return map[string]any{"iss": f.server.URL, "sub": "subject", "aud": "workload", "exp": time.Now().Add(time.Hour).Unix(), "iat": time.Now().Unix(), "groups": []string{"operators"}, "tenant": "allowed"}
}
func (f *authFixture) sign(t *testing.T, c map[string]any) string {
	t.Helper()
	b, err := json.Marshal(c)
	if err != nil {
		t.Fatal(err)
	}
	return f.signRaw(t, string(b))
}
func (f *authFixture) signRaw(t *testing.T, payload string) string {
	t.Helper()
	raw := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"RS256","kid":"test"}`)) + "." + base64.RawURLEncoding.EncodeToString([]byte(payload))
	h := sha256.Sum256([]byte(raw))
	sig, err := rsa.SignPKCS1v15(rand.Reader, f.key, crypto.SHA256, h[:])
	if err != nil {
		t.Fatal(err)
	}
	return raw + "." + base64.RawURLEncoding.EncodeToString(sig)
}
func (f *authFixture) auth(t *testing.T) *Auth {
	t.Helper()
	c := IssuerConfig{URL: f.server.URL, Audience: "workload", GroupsClaim: "groups", RequiredClaims: map[string]string{"tenant": "allowed"}}
	a, err := NewAuth(context.Background(), []IssuerConfig{c}, HumanConfig{IssuerConfig: c, ClientID: "browser"}, "https://app.example")
	if err != nil {
		t.Fatal(err)
	}
	return a
}

func TestAuthVerifiedBearer(t *testing.T) {
	f := newAuthFixture(t)
	a := f.auth(t)
	for _, tc := range []struct {
		name   string
		mutate func(map[string]any)
	}{
		{"valid", func(c map[string]any) {}},
		{"expired", func(c map[string]any) { c["exp"] = time.Now().Add(-time.Minute).Unix() }},
		{"future", func(c map[string]any) { c["nbf"] = time.Now().Add(time.Hour).Unix() }},
		{"audience", func(c map[string]any) { c["aud"] = "other" }},
		{"issuer", func(c map[string]any) { c["iss"] = "https://other.example" }},
		{"groups", func(c map[string]any) { c["groups"] = []any{"ok", 42} }},
		{"required", func(c map[string]any) { delete(c, "tenant") }},
		{"subject", func(c map[string]any) { c["sub"] = "" }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			c := f.claims()
			tc.mutate(c)
			r := httptest.NewRequest("GET", "https://app.example/", nil)
			r.Header.Set("Authorization", "Bearer "+f.sign(t, c))
			id, err := a.Authenticate(r)
			if tc.name == "valid" {
				if err != nil || id.Human || id.Subject != "subject" || len(id.Groups) != 1 {
					t.Fatalf("unexpected identity: %v", err)
				}
			} else if err == nil {
				t.Fatal("accepted invalid token")
			}
		})
	}
	c := f.claims()
	b, _ := json.Marshal(c)
	duplicate := string(b[:len(b)-1]) + `,"sub":"attacker"}`
	for _, raw := range []string{f.signRaw(t, duplicate), "unsigned", f.sign(t, c) + "broken"} {
		r := httptest.NewRequest("GET", "/", nil)
		r.Header.Set("Authorization", "Bearer "+raw)
		if _, err := a.Authenticate(r); err == nil {
			t.Fatal("accepted malformed token")
		}
	}
	r := httptest.NewRequest("GET", "/", nil)
	r.Header.Add("Authorization", "Bearer "+f.sign(t, c))
	r.Header.Add("Authorization", "Bearer "+f.sign(t, c))
	if _, err := a.Authenticate(r); err == nil {
		t.Fatal("accepted duplicate authorization")
	}
}

func TestAuthBrowserSession(t *testing.T) {
	f := newAuthFixture(t)
	a := f.auth(t)
	w := httptest.NewRecorder()
	a.Login(w, httptest.NewRequest("GET", "https://app.example/login?return=https://evil.example", nil))
	if w.Code != 302 {
		t.Fatal(w.Code)
	}
	u, err := url.Parse(w.Header().Get("Location"))
	if err != nil {
		t.Fatal(err)
	}
	q := u.Query()
	f.nonce = q.Get("nonce")
	f.challenge = q.Get("code_challenge")
	if f.nonce == "" || f.challenge == "" || q.Get("code_challenge_method") != "S256" || q.Get("redirect_uri") != "https://app.example/callback" {
		t.Fatal("missing oidc protections")
	}
	login := w.Result().Cookies()[0]
	if !login.Secure || !login.HttpOnly || login.SameSite != http.SameSiteLaxMode {
		t.Fatal("unsafe cookie")
	}
	callback := func(cookie *http.Cookie) *httptest.ResponseRecorder {
		r := httptest.NewRequest("GET", "https://app.example/callback?code=test-code&state="+url.QueryEscape(q.Get("state")), nil)
		if cookie != nil {
			r.AddCookie(cookie)
		}
		out := httptest.NewRecorder()
		a.Callback(out, r)
		return out
	}
	if callback(nil).Code != 400 {
		t.Fatal("accepted unbound callback")
	}
	w = callback(login)
	if w.Code != 303 || w.Header().Get("Location") != "/" {
		t.Fatalf("callback failed: %d", w.Code)
	}
	if callback(login).Code != 400 {
		t.Fatal("accepted callback replay")
	}
	var session *http.Cookie
	for _, c := range w.Result().Cookies() {
		if c.Name == sessionCookie {
			session = c
		}
	}
	if session == nil {
		t.Fatal("missing session")
	}
	r := httptest.NewRequest("POST", "https://app.example/logout", nil)
	r.AddCookie(session)
	id, err := a.Authenticate(r)
	if err != nil || !id.Human {
		t.Fatal("missing human identity")
	}
	if a.CheckCSRF(r) {
		t.Fatal("accepted missing csrf")
	}
	r.Header.Set("X-CSRF-Token", a.CSRF(r))
	if !a.CheckCSRF(r) {
		t.Fatal("rejected csrf")
	}
	r.Header.Set("Origin", "https://evil.example")
	if a.CheckCSRF(r) {
		t.Fatal("accepted cross origin")
	}
	r.Header.Del("Origin")
	r.Header.Set("Authorization", "Bearer invalid")
	if _, err := a.Authenticate(r); err == nil {
		t.Fatal("fell back from invalid bearer")
	}
	r.Header.Del("Authorization")
	restarted := f.auth(t)
	if _, err := restarted.Authenticate(r); err == nil || restarted.CheckCSRF(r) {
		t.Fatal("session survived restart")
	}
	w = httptest.NewRecorder()
	a.Logout(w, r)
	if w.Code != 303 {
		t.Fatal(w.Code)
	}
	if _, err := a.Authenticate(r); err == nil || a.CheckCSRF(r) {
		t.Fatal("session survived logout")
	}
}

func TestAuthRejectInsecureConfiguration(t *testing.T) {
	if _, err := NewAuth(context.Background(), nil, HumanConfig{}, "http://app.example"); err == nil {
		t.Fatal("accepted insecure base url")
	}
}
