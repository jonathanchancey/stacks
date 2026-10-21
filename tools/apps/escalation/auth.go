package main

import (
	"context"
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

type Identity struct {
	Issuer  string         `json:"issuer"`
	Subject string         `json:"subject"`
	Groups  []string       `json:"groups,omitempty"`
	Claims  map[string]any `json:"-"`
	Human   bool           `json:"-"`
}

type IssuerConfig struct {
	URL            string            `json:"url"`
	Audience       string            `json:"audience"`
	RequiredClaims map[string]string `json:"requiredClaims,omitempty"`
	GroupsClaim    string            `json:"groupsClaim,omitempty"`
}

type HumanConfig struct {
	IssuerConfig
	ClientID         string `json:"clientID"`
	ClientSecretFile string `json:"clientSecretFile"`
}

type authIssuer struct {
	config   IssuerConfig
	verifier *oidc.IDTokenVerifier
}
type authSession struct {
	identity Identity
	expires  time.Time
	csrf     string
}
type authPending struct {
	expires                  time.Time
	nonce, verifier, binding string
}
type Auth struct {
	issuers  []authIssuer
	human    *authIssuer
	oauth    oauth2.Config
	secure   bool
	origin   string
	mu       sync.Mutex
	sessions map[string]authSession
	pending  map[string]authPending
}

const sessionCookie = "escalation_session"
const loginCookie = "escalation_login"
const authLimit = 1024

func validAuthURL(raw string) bool {
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" || u.User != nil || u.RawQuery != "" || u.Fragment != "" {
		return false
	}
	ip := net.ParseIP(u.Hostname())
	return u.Scheme == "https" || (u.Scheme == "http" && (u.Hostname() == "localhost" || (ip != nil && ip.IsLoopback())))
}

func NewAuth(ctx context.Context, issuers []IssuerConfig, human HumanConfig, baseURL string) (*Auth, error) {
	if !validAuthURL(baseURL) {
		return nil, errors.New("invalid base url")
	}
	u, _ := url.Parse(baseURL)
	if u.Path != "" && u.Path != "/" {
		return nil, errors.New("base url must have no path")
	}
	a := &Auth{secure: u.Scheme == "https", origin: strings.TrimSuffix(baseURL, "/"), sessions: make(map[string]authSession), pending: make(map[string]authPending)}
	load := func(c IssuerConfig, audience string) (authIssuer, *oidc.Provider, error) {
		if !validAuthURL(c.URL) || audience == "" {
			return authIssuer{}, nil, errors.New("invalid issuer configuration")
		}
		p, err := oidc.NewProvider(ctx, c.URL)
		if err != nil {
			return authIssuer{}, nil, errors.New("issuer discovery failed")
		}
		return authIssuer{c, p.Verifier(&oidc.Config{ClientID: audience})}, p, nil
	}
	for _, c := range issuers {
		v, _, err := load(c, c.Audience)
		if err != nil {
			return nil, err
		}
		a.issuers = append(a.issuers, v)
	}
	if human.URL != "" {
		v, p, err := load(human.IssuerConfig, human.ClientID)
		if err != nil {
			return nil, err
		}
		a.human = &v
		secret := ""
		if human.ClientSecretFile != "" {
			b, err := os.ReadFile(human.ClientSecretFile)
			if err != nil {
				return nil, errors.New("cannot read client secret")
			}
			secret = strings.TrimSpace(string(b))
		}
		a.oauth = oauth2.Config{ClientID: human.ClientID, ClientSecret: secret, Endpoint: p.Endpoint(), RedirectURL: a.origin + "/callback", Scopes: []string{oidc.ScopeOpenID, "profile", "groups"}}
	}
	return a, nil
}

// reject duplicate object keys at every depth, including claims inside objects.
func uniqueJSON(d *json.Decoder) error {
	t, err := d.Token()
	if err != nil {
		return err
	}
	if delim, ok := t.(json.Delim); ok {
		switch delim {
		case '{':
			seen := map[string]bool{}
			for d.More() {
				k, err := d.Token()
				if err != nil {
					return err
				}
				s, ok := k.(string)
				if !ok || seen[s] {
					return errors.New("duplicate claim")
				}
				seen[s] = true
				if err := uniqueJSON(d); err != nil {
					return err
				}
			}
		case '[':
			for d.More() {
				if err := uniqueJSON(d); err != nil {
					return err
				}
			}
		default:
			return errors.New("invalid json")
		}
		_, err = d.Token()
		return err
	}
	return nil
}

func (v authIssuer) verify(ctx context.Context, raw string) (Identity, time.Time, error) {
	fail := errors.New("invalid identity token")
	if len(raw) > 65536 {
		return Identity{}, time.Time{}, fail
	}
	parts := strings.Split(raw, ".")
	if len(parts) != 3 {
		return Identity{}, time.Time{}, fail
	}
	for _, part := range parts[:2] {
		b, err := base64.RawURLEncoding.DecodeString(part)
		if err != nil {
			return Identity{}, time.Time{}, fail
		}
		d := json.NewDecoder(strings.NewReader(string(b)))
		if uniqueJSON(d) != nil {
			return Identity{}, time.Time{}, fail
		}
		if _, err = d.Token(); err != io.EOF {
			return Identity{}, time.Time{}, fail
		}
	}
	t, err := v.verifier.Verify(ctx, raw)
	if err != nil || t.Subject == "" || !t.Expiry.After(time.Now()) {
		return Identity{}, time.Time{}, fail
	}
	var claims map[string]any
	if t.Claims(&claims) != nil {
		return Identity{}, time.Time{}, fail
	}
	if n, ok := claims["nbf"]; ok {
		f, ok := n.(float64)
		if !ok || f > float64(time.Now().Unix()) {
			return Identity{}, time.Time{}, fail
		}
	}
	for k, want := range v.config.RequiredClaims {
		got, ok := claims[k].(string)
		if !ok || got != want {
			return Identity{}, time.Time{}, fail
		}
	}
	id := Identity{Issuer: t.Issuer, Subject: t.Subject, Claims: claims}
	if v.config.GroupsClaim != "" {
		if g, exists := claims[v.config.GroupsClaim]; exists {
			arr, ok := g.([]any)
			if !ok {
				return Identity{}, time.Time{}, fail
			}
			for _, item := range arr {
				s, ok := item.(string)
				if !ok || s == "" {
					return Identity{}, time.Time{}, fail
				}
				id.Groups = append(id.Groups, s)
			}
		}
	}
	return id, t.Expiry, nil
}

func (a *Auth) prune() {
	now := time.Now()
	for k, s := range a.sessions {
		if !s.expires.After(now) {
			delete(a.sessions, k)
		}
	}
	for k, s := range a.pending {
		if !s.expires.After(now) {
			delete(a.pending, k)
		}
	}
}

func singleCookie(r *http.Request, name string) string {
	value := ""
	count := 0
	for _, c := range r.Cookies() {
		if c.Name == name {
			value = c.Value
			count++
		}
	}
	if count != 1 {
		return ""
	}
	return value
}

func (a *Auth) Authenticate(r *http.Request) (Identity, error) {
	if headers := r.Header.Values("Authorization"); len(headers) > 0 {
		if len(headers) != 1 {
			return Identity{}, errors.New("invalid authorization")
		}
		parts := strings.Split(headers[0], " ")
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
			return Identity{}, errors.New("invalid authorization")
		}
		for _, v := range a.issuers {
			id, _, err := v.verify(r.Context(), parts[1])
			if err == nil {
				return id, nil
			}
		}
		return Identity{}, errors.New("invalid bearer token")
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	a.prune()
	s, ok := a.sessions[singleCookie(r, sessionCookie)]
	if !ok {
		return Identity{}, errors.New("authentication required")
	}
	// return a copy so request handlers cannot mutate identities shared by sessions.
	b, _ := json.Marshal(s.identity.Claims)
	var claims map[string]any
	_ = json.Unmarshal(b, &claims)
	id := s.identity
	id.Claims = claims
	id.Groups = append([]string(nil), id.Groups...)
	return id, nil
}

func authRandom() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}
func (a *Auth) cookie(w http.ResponseWriter, name, value string, age int) {
	http.SetCookie(w, &http.Cookie{Name: name, Value: value, Path: "/", Secure: a.secure, HttpOnly: true, SameSite: http.SameSiteLaxMode, MaxAge: age})
}

func (a *Auth) Login(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	if r.Method != http.MethodGet || a.human == nil {
		http.Error(w, "login unavailable", http.StatusBadRequest)
		return
	}
	state, e1 := authRandom()
	nonce, e2 := authRandom()
	binding, e3 := authRandom()
	verifier, e4 := authRandom()
	if e1 != nil || e2 != nil || e3 != nil || e4 != nil {
		http.Error(w, "login unavailable", 500)
		return
	}
	a.mu.Lock()
	a.prune()
	if len(a.pending) >= authLimit {
		a.mu.Unlock()
		http.Error(w, "login capacity reached", 503)
		return
	}
	a.pending[state] = authPending{time.Now().Add(5 * time.Minute), nonce, verifier, binding}
	a.mu.Unlock()
	a.cookie(w, loginCookie, binding, 300)
	http.Redirect(w, r, a.oauth.AuthCodeURL(state, oidc.Nonce(nonce), oauth2.S256ChallengeOption(verifier)), http.StatusFound)
}

func (a *Auth) Callback(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	bad := func() { http.Error(w, "invalid login callback", http.StatusBadRequest) }
	q, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil || r.Method != http.MethodGet || a.human == nil || len(q["state"]) != 1 || len(q["code"]) != 1 || q.Get("code") == "" || q.Has("error") {
		bad()
		return
	}
	a.mu.Lock()
	a.prune()
	p, ok := a.pending[q.Get("state")]
	if ok && subtle.ConstantTimeCompare([]byte(p.binding), []byte(singleCookie(r, loginCookie))) == 1 {
		delete(a.pending, q.Get("state"))
	} else {
		ok = false
	}
	a.mu.Unlock()
	if !ok {
		bad()
		return
	}
	a.cookie(w, loginCookie, "", -1)
	tok, err := a.oauth.Exchange(r.Context(), q.Get("code"), oauth2.VerifierOption(p.verifier))
	if err != nil {
		bad()
		return
	}
	raw, ok := tok.Extra("id_token").(string)
	if !ok {
		bad()
		return
	}
	id, expiry, err := a.human.verify(r.Context(), raw)
	if err != nil {
		bad()
		return
	}
	nonce, ok := id.Claims["nonce"].(string)
	if !ok || subtle.ConstantTimeCompare([]byte(nonce), []byte(p.nonce)) != 1 {
		bad()
		return
	}
	id.Human = true
	key, e1 := authRandom()
	csrf, e2 := authRandom()
	if e1 != nil || e2 != nil {
		bad()
		return
	}
	if limit := time.Now().Add(time.Hour); expiry.After(limit) {
		expiry = limit
	}
	a.mu.Lock()
	a.prune()
	if len(a.sessions) >= authLimit {
		a.mu.Unlock()
		http.Error(w, "session capacity reached", 503)
		return
	}
	delete(a.sessions, singleCookie(r, sessionCookie))
	a.sessions[key] = authSession{id, expiry, csrf}
	a.mu.Unlock()
	a.cookie(w, sessionCookie, key, int(time.Until(expiry).Seconds()))
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func (a *Auth) CSRF(r *http.Request) string {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.prune()
	return a.sessions[singleCookie(r, sessionCookie)].csrf
}
func (a *Auth) CheckCSRF(r *http.Request) bool {
	if origins := r.Header.Values("Origin"); len(origins) > 0 && (len(origins) != 1 || origins[0] != a.origin) {
		return false
	}
	want := a.CSRF(r)
	got := r.Header.Values("X-CSRF-Token")
	if len(got) == 0 && r.Method == http.MethodPost && strings.HasPrefix(r.Header.Get("Content-Type"), "application/x-www-form-urlencoded") {
		if err := r.ParseForm(); err != nil {
			return false
		}
		got = r.PostForm["csrf"]
	}
	return want != "" && len(got) == 1 && subtle.ConstantTimeCompare([]byte(want), []byte(got[0])) == 1
}
func (a *Auth) Logout(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	if r.Method != http.MethodPost || !a.CheckCSRF(r) {
		http.Error(w, "invalid csrf token", http.StatusForbidden)
		return
	}
	a.mu.Lock()
	delete(a.sessions, singleCookie(r, sessionCookie))
	a.mu.Unlock()
	a.cookie(w, sessionCookie, "", -1)
	http.Redirect(w, r, "/", http.StatusSeeOther)
}
