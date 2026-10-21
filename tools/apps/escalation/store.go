package main

import (
	"context"
	"encoding/json"
	"time"

	rbac "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/dynamic"
)

var requests = schema.GroupVersionResource{Group: group, Version: "v1alpha1", Resource: "accessrequests"}

type Spec struct {
	Requester       Identity          `json:"requester"`
	Profile         Profile           `json:"profile"`
	Namespace       string            `json:"namespace"`
	DurationSeconds int64             `json:"durationSeconds"`
	Reason          string            `json:"reason"`
	PendingUntil    time.Time         `json:"pendingUntil"`
	RoleUID         types.UID         `json:"roleUID"`
	Rules           []rbac.PolicyRule `json:"rules"`
	ScopeHash       string            `json:"scopeHash"`
	IdempotencyHash string            `json:"idempotencyHash"`
}

type Status struct {
	Phase        string     `json:"phase"`
	Actor        *Identity  `json:"actor,omitempty"`
	Deadline     *time.Time `json:"deadline,omitempty"`
	AccountUID   types.UID  `json:"accountUID,omitempty"`
	BindingUID   types.UID  `json:"bindingUID,omitempty"`
	IssuedExpiry *time.Time `json:"issuedExpiry,omitempty"`
	Message      string     `json:"message,omitempty"`
}

type Request struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata"`
	Spec              Spec   `json:"spec"`
	Status            Status `json:"status,omitempty"`
}

func (r *Request) grantName() string { return "grant-" + string(r.UID) }
func (r *Request) terminal(now time.Time) bool {
	return r.DeletionTimestamp != nil || r.Status.Phase == "denied" || r.Status.Phase == "revoked" || r.Status.Phase == "expired" || r.Status.Phase == "failed" || (r.Status.Deadline != nil && !now.Before(*r.Status.Deadline)) || (r.Status.Deadline == nil && !now.Before(r.Spec.PendingUntil))
}

type Store struct{ client dynamic.ResourceInterface }

func newStore(d dynamic.Interface, namespace string) *Store {
	return &Store{d.Resource(requests).Namespace(namespace)}
}
func decodeRequest(u *unstructured.Unstructured) (*Request, error) {
	b, e := json.Marshal(u.Object)
	if e != nil {
		return nil, e
	}
	var r Request
	e = json.Unmarshal(b, &r)
	return &r, e
}
func encodeRequest(r *Request) (*unstructured.Unstructured, error) {
	b, e := json.Marshal(r)
	if e != nil {
		return nil, e
	}
	var obj map[string]any
	e = json.Unmarshal(b, &obj)
	return &unstructured.Unstructured{Object: obj}, e
}
func (s *Store) get(ctx context.Context, id string) (*Request, error) {
	u, e := s.client.Get(ctx, id, metav1.GetOptions{})
	if e != nil {
		return nil, e
	}
	return decodeRequest(u)
}
func (s *Store) create(ctx context.Context, r *Request) (*Request, error) {
	u, e := encodeRequest(r)
	if e != nil {
		return nil, e
	}
	u, e = s.client.Create(ctx, u, metav1.CreateOptions{})
	if e != nil {
		return nil, e
	}
	return decodeRequest(u)
}
func (s *Store) update(ctx context.Context, r *Request) (*Request, error) {
	u, e := encodeRequest(r)
	if e != nil {
		return nil, e
	}
	u, e = s.client.Update(ctx, u, metav1.UpdateOptions{})
	if e != nil {
		return nil, e
	}
	return decodeRequest(u)
}
func (s *Store) status(ctx context.Context, r *Request) (*Request, error) {
	u, e := encodeRequest(r)
	if e != nil {
		return nil, e
	}
	u, e = s.client.UpdateStatus(ctx, u, metav1.UpdateOptions{})
	if e != nil {
		return nil, e
	}
	return decodeRequest(u)
}
func (s *Store) list(ctx context.Context, limit int64, cont string) ([]*Request, string, error) {
	l, e := s.client.List(ctx, metav1.ListOptions{Limit: limit, Continue: cont})
	if e != nil {
		return nil, "", e
	}
	out := make([]*Request, 0, len(l.Items))
	for i := range l.Items {
		r, e := decodeRequest(&l.Items[i])
		if e != nil {
			return nil, "", e
		}
		out = append(out, r)
	}
	return out, l.GetContinue(), nil
}
