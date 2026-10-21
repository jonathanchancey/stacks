package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"slices"
	"strings"
	"time"

	rbac "k8s.io/api/rbac/v1"
	"k8s.io/apimachinery/pkg/util/validation"
	"sigs.k8s.io/yaml"
)

const group = "escalation.stacks.dev"
const ownership = group + "/request"
const finalizer = group + "/cleanup"

type Config struct {
	Listen           string         `json:"listen"`
	BaseURL          string         `json:"baseURL"`
	Namespace        string         `json:"namespace"`
	GrantNamespace   string         `json:"grantNamespace"`
	Audience         string         `json:"audience"`
	KubeServer       string         `json:"kubeServer"`
	KubeCAFile       string         `json:"kubeCAFile"`
	KubeTLSName      string         `json:"kubeTLSName,omitempty"`
	ClockSkewSeconds int            `json:"clockSkewSeconds"`
	Issuers          []IssuerConfig `json:"issuers"`
	Human            HumanConfig    `json:"human"`
	Profiles         []Profile      `json:"profiles"`
}

type Role struct {
	Kind string `json:"kind"`
	Name string `json:"name"`
}

type Profile struct {
	Name             string   `json:"name"`
	Role             Role     `json:"role"`
	Namespaces       []string `json:"namespaces"`
	Cluster          bool     `json:"cluster"`
	RequesterIssuers []string `json:"requesterIssuers"`
	RequesterGroups  []string `json:"requesterGroups,omitempty"`
	ApproverGroups   []string `json:"approverGroups"`
	MaxDuration      string   `json:"maxDuration"`
	PendingDuration  string   `json:"pendingDuration"`
}

func loadConfig(path string) (Config, error) {
	var c Config
	b, err := os.ReadFile(path)
	if err != nil {
		return c, err
	}
	if err = yaml.UnmarshalStrict(b, &c); err != nil {
		return c, err
	}
	if c.Listen == "" {
		c.Listen = ":8080"
	}
	c.BaseURL = strings.TrimSuffix(c.BaseURL, "/")
	if err = c.validate(); err != nil {
		return c, err
	}
	return c, nil
}

func (c Config) budget() time.Duration { return time.Duration(60+c.ClockSkewSeconds) * time.Second }

func (c Config) validate() error {
	for _, ns := range []string{c.Namespace, c.GrantNamespace} {
		if len(validation.IsDNS1123Label(ns)) != 0 {
			return errors.New("invalid service or grant namespace")
		}
	}
	if c.Namespace == c.GrantNamespace {
		return errors.New("grant namespace must be separate from server namespace")
	}
	if c.ClockSkewSeconds < 1 || c.ClockSkewSeconds > 300 {
		return errors.New("clockSkewSeconds must be between 1 and 300")
	}
	for _, raw := range []string{c.BaseURL, c.KubeServer} {
		u, err := url.Parse(raw)
		if err != nil || u.Host == "" || u.User != nil || u.RawQuery != "" || u.Fragment != "" || (u.Scheme != "https" && !(u.Scheme == "http" && (u.Hostname() == "127.0.0.1" || u.Hostname() == "localhost"))) {
			return errors.New("baseURL and kubeServer require https (http allowed only on loopback)")
		}
	}
	if c.Audience == "" || c.KubeCAFile == "" || len(c.Issuers) == 0 || len(c.Profiles) == 0 {
		return errors.New("audience, kubeCAFile, issuers and profiles are required")
	}
	if c.Human.URL == "" || c.Human.ClientID == "" || c.Human.GroupsClaim == "" {
		return errors.New("human issuer, clientID and groupsClaim are required")
	}
	issuers := map[string]bool{}
	for _, i := range c.Issuers {
		if issuers[i.URL] {
			return errors.New("requester issuers must have unique urls")
		}
		issuers[i.URL] = true
	}
	seen := map[string]bool{}
	for _, p := range c.Profiles {
		if seen[p.Name] || len(validation.IsDNS1123Label(p.Name)) != 0 {
			return errors.New("profile names must be unique dns labels")
		}
		seen[p.Name] = true
		if p.Role.Name == "" || (p.Role.Kind != "Role" && p.Role.Kind != "ClusterRole") || len(p.ApproverGroups) == 0 || len(p.RequesterIssuers) == 0 {
			return fmt.Errorf("invalid profile %s", p.Name)
		}
		if p.Cluster && (p.Role.Kind != "ClusterRole" || len(p.Namespaces) != 0) {
			return errors.New("cluster profiles require a ClusterRole and no namespaces")
		}
		if !p.Cluster && len(p.Namespaces) == 0 {
			return errors.New("namespace profiles require namespaces")
		}
		for _, ns := range p.Namespaces {
			if ns == c.GrantNamespace || ns == c.Namespace || len(validation.IsDNS1123Label(ns)) != 0 {
				return errors.New("profile namespace is invalid or reserved")
			}
		}
		for _, issuer := range p.RequesterIssuers {
			if !slices.ContainsFunc(c.Issuers, func(i IssuerConfig) bool { return i.URL == issuer }) {
				return errors.New("profile references unknown requester issuer")
			}
		}
		max, err := time.ParseDuration(p.MaxDuration)
		if err != nil || max < 10*time.Minute+c.budget()+time.Second || max > 24*time.Hour {
			return errors.New("maxDuration must fit token minimum and timing budget, and not exceed 24h")
		}
		pending, err := time.ParseDuration(p.PendingDuration)
		if err != nil || pending <= 0 || pending > 24*time.Hour {
			return errors.New("invalid pendingDuration")
		}
	}
	return nil
}

func digest(v any) string {
	b, _ := json.Marshal(v)
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
func sameIdentity(a, b Identity) bool { return a.Issuer == b.Issuer && a.Subject == b.Subject }
func anyGroup(have, allowed []string) bool {
	return slices.ContainsFunc(have, func(g string) bool { return slices.Contains(allowed, g) })
}
func (p Profile) requester(i Identity) bool {
	return slices.Contains(p.RequesterIssuers, i.Issuer) && (len(p.RequesterGroups) == 0 || anyGroup(i.Groups, p.RequesterGroups))
}
func (p Profile) approver(i Identity) bool { return i.Human && anyGroup(i.Groups, p.ApproverGroups) }
func (p Profile) permits(ns string) bool {
	return (p.Cluster && ns == "") || (!p.Cluster && slices.Contains(p.Namespaces, ns))
}

// Reject roles that directly allow extending or replacing the grant. Indirect
// privilege paths still require an operator's review of the role and workloads.
func safeRules(rules []rbac.PolicyRule) error {
	for _, r := range rules {
		for _, v := range r.Verbs {
			if v == "*" || v == "bind" || v == "escalate" || v == "impersonate" {
				return errors.New("role permits privilege persistence")
			}
		}
		for _, resource := range r.Resources {
			if strings.Contains(resource, "*") || resource == "secrets" || resource == "serviceaccounts/token" || slices.Contains([]string{"pods/exec", "pods/attach", "pods/proxy", "nodes/proxy"}, resource) {
				return errors.New("role permits credential access or privilege persistence")
			}
			if slices.Contains([]string{"roles", "clusterroles", "rolebindings", "clusterrolebindings", "certificatesigningrequests", "serviceaccounts", "pods", "pods/ephemeralcontainers", "deployments", "replicasets", "replicationcontrollers", "statefulsets", "daemonsets", "jobs", "cronjobs"}, resource) {
				if slices.ContainsFunc(r.Verbs, func(v string) bool { return v != "get" && v != "list" && v != "watch" && v != "delete" }) || (slices.Contains(r.Verbs, "delete") && !slices.Contains([]string{"pods", "jobs"}, resource)) {
					return errors.New("role permits credential access or privilege persistence")
				}
			}
		}
	}
	return nil
}
