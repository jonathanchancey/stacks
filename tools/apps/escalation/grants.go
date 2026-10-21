package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"log/slog"
	"slices"
	"strings"
	"sync"
	"time"

	authv1 "k8s.io/api/authentication/v1"
	core "k8s.io/api/core/v1"
	rbac "k8s.io/api/rbac/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
)

type App struct {
	config          Config
	kube            kubernetes.Interface
	store           *Store
	auth            *Auth
	mu              sync.Mutex
	now             func() time.Time
	lastReconcile   time.Time
	reconcileErrors uint64
	overdue         uint64
	rate            map[string]rateWindow
}

var errGrantChanged = errors.New("grant objects changed or disappeared; refusing reactivation")

func (a *App) role(ctx context.Context, p Profile, ns string) (types.UID, []rbac.PolicyRule, error) {
	if p.Role.Kind == "Role" {
		r, e := a.kube.RbacV1().Roles(ns).Get(ctx, p.Role.Name, metav1.GetOptions{})
		if e != nil {
			return "", nil, e
		}
		return r.UID, r.Rules, safeRules(r.Rules)
	}
	r, e := a.kube.RbacV1().ClusterRoles().Get(ctx, p.Role.Name, metav1.GetOptions{})
	if e != nil {
		return "", nil, e
	}
	if r.AggregationRule != nil {
		return "", nil, errors.New("aggregated roles are not immutable permission profiles")
	}
	return r.UID, r.Rules, safeRules(r.Rules)
}

func (a *App) unchanged(ctx context.Context, r *Request) error {
	index := slices.IndexFunc(a.config.Profiles, func(p Profile) bool { return p.Name == r.Spec.Profile.Name })
	if index < 0 || digest(a.config.Profiles[index]) != digest(r.Spec.Profile) {
		return errors.New("profile changed or removed")
	}
	uid, rules, err := a.role(ctx, r.Spec.Profile, r.Spec.Namespace)
	if err != nil {
		return err
	}
	if uid != r.Spec.RoleUID || digest(rules) != digest(r.Spec.Rules) {
		return errors.New("role changed")
	}
	return nil
}

func (a *App) ensure(ctx context.Context, r *Request) error {
	if !slices.Contains(r.Finalizers, finalizer) {
		r.Finalizers = append(r.Finalizers, finalizer)
		updated, e := a.store.update(ctx, r)
		if e != nil {
			return e
		}
		*r = *updated
	}
	// Persist each creation attempt first. After a crash, an absent object is
	// ambiguous and must fail closed rather than recreate possibly revoked access.
	createAccount := r.Status.Phase == "approved"
	createBinding := createAccount || r.Status.Phase == "provisioning"
	if createAccount {
		r.Status.Phase = "provisioning"
		updated, e := a.store.status(ctx, r)
		if e != nil {
			return e
		}
		*r = *updated
	}
	name := r.grantName()
	labels := map[string]string{ownership: string(r.UID)}
	disabled := false
	accounts := a.kube.CoreV1().ServiceAccounts(a.config.GrantNamespace)
	sa, err := accounts.Get(ctx, name, metav1.GetOptions{})
	if apierrors.IsNotFound(err) {
		if r.Status.AccountUID != "" || !createAccount {
			return errGrantChanged
		}
		sa, err = accounts.Create(ctx, &core.ServiceAccount{ObjectMeta: metav1.ObjectMeta{Name: name, Labels: labels}, AutomountServiceAccountToken: &disabled}, metav1.CreateOptions{})
	}
	if err != nil {
		return err
	}
	if sa.Labels[ownership] != string(r.UID) || (r.Status.AccountUID != "" && sa.UID != r.Status.AccountUID) || sa.AutomountServiceAccountToken == nil || *sa.AutomountServiceAccountToken || len(sa.Secrets) != 0 || sa.DeletionTimestamp != nil {
		return errGrantChanged
	}
	if r.Status.AccountUID == "" {
		r.Status.AccountUID = sa.UID
		updated, e := a.store.status(ctx, r)
		if e != nil {
			return e
		}
		*r = *updated
	}
	if createBinding {
		r.Status.Phase = "binding"
		updated, e := a.store.status(ctx, r)
		if e != nil {
			return e
		}
		*r = *updated
	}
	subjects := []rbac.Subject{{Kind: "ServiceAccount", Name: name, Namespace: a.config.GrantNamespace}}
	ref := rbac.RoleRef{APIGroup: rbac.GroupName, Kind: r.Spec.Profile.Role.Kind, Name: r.Spec.Profile.Role.Name}
	var meta metav1.Object
	var actualSubjects []rbac.Subject
	var actualRef rbac.RoleRef
	if r.Spec.Profile.Cluster {
		bindings := a.kube.RbacV1().ClusterRoleBindings()
		b, e := bindings.Get(ctx, name, metav1.GetOptions{})
		if apierrors.IsNotFound(e) {
			if r.Status.BindingUID != "" || !createBinding {
				return errGrantChanged
			}
			b, e = bindings.Create(ctx, &rbac.ClusterRoleBinding{ObjectMeta: metav1.ObjectMeta{Name: name, Labels: labels}, Subjects: subjects, RoleRef: ref}, metav1.CreateOptions{})
		}
		if e != nil {
			return e
		}
		meta = b
		actualSubjects = b.Subjects
		actualRef = b.RoleRef
	} else {
		bindings := a.kube.RbacV1().RoleBindings(r.Spec.Namespace)
		b, e := bindings.Get(ctx, name, metav1.GetOptions{})
		if apierrors.IsNotFound(e) {
			if r.Status.BindingUID != "" || !createBinding {
				return errGrantChanged
			}
			b, e = bindings.Create(ctx, &rbac.RoleBinding{ObjectMeta: metav1.ObjectMeta{Name: name, Labels: labels}, Subjects: subjects, RoleRef: ref}, metav1.CreateOptions{})
		}
		if e != nil {
			return e
		}
		meta = b
		actualSubjects = b.Subjects
		actualRef = b.RoleRef
	}
	if meta.GetLabels()[ownership] != string(r.UID) || (r.Status.BindingUID != "" && meta.GetUID() != r.Status.BindingUID) || digest(subjects) != digest(actualSubjects) || actualRef != ref || meta.GetDeletionTimestamp() != nil {
		return errGrantChanged
	}
	r.Status.BindingUID = meta.GetUID()
	return nil
}

func (a *App) cleanup(ctx context.Context, r *Request) error {
	name := r.grantName()
	// Attempt both deletions even if one is unavailable. Account deletion revokes
	// every token issued for this grant; binding deletion removes its permissions.
	var errs []error
	accounts := a.kube.CoreV1().ServiceAccounts(a.config.GrantNamespace)
	sa, e := accounts.Get(ctx, name, metav1.GetOptions{})
	if e == nil {
		if sa.Labels[ownership] != string(r.UID) || (r.Status.AccountUID != "" && sa.UID != r.Status.AccountUID) {
			errs = append(errs, errors.New("refusing unrelated account cleanup"))
		} else {
			uid := sa.UID
			e = accounts.Delete(ctx, name, metav1.DeleteOptions{Preconditions: &metav1.Preconditions{UID: &uid}})
			if e != nil && !apierrors.IsNotFound(e) {
				errs = append(errs, e)
			}
		}
	} else if !apierrors.IsNotFound(e) {
		errs = append(errs, e)
	}
	var b metav1.Object
	if r.Spec.Profile.Cluster {
		b, e = a.kube.RbacV1().ClusterRoleBindings().Get(ctx, name, metav1.GetOptions{})
	} else {
		b, e = a.kube.RbacV1().RoleBindings(r.Spec.Namespace).Get(ctx, name, metav1.GetOptions{})
	}
	if e == nil {
		if b.GetLabels()[ownership] != string(r.UID) || (r.Status.BindingUID != "" && b.GetUID() != r.Status.BindingUID) {
			errs = append(errs, errors.New("refusing unrelated binding cleanup"))
		} else {
			uid := b.GetUID()
			opts := metav1.DeleteOptions{Preconditions: &metav1.Preconditions{UID: &uid}}
			if r.Spec.Profile.Cluster {
				e = a.kube.RbacV1().ClusterRoleBindings().Delete(ctx, name, opts)
			} else {
				e = a.kube.RbacV1().RoleBindings(r.Spec.Namespace).Delete(ctx, name, opts)
			}
			if e != nil && !apierrors.IsNotFound(e) {
				errs = append(errs, e)
			}
		}
	} else if !apierrors.IsNotFound(e) {
		errs = append(errs, e)
	}
	if len(errs) > 0 {
		return errors.Join(errs...)
	}
	// DELETE acceptance does not prove absence when admission/finalizers delay it.
	if _, e = accounts.Get(ctx, name, metav1.GetOptions{}); !apierrors.IsNotFound(e) {
		if e != nil {
			return e
		}
		return errors.New("account deletion pending")
	}
	if r.Spec.Profile.Cluster {
		_, e = a.kube.RbacV1().ClusterRoleBindings().Get(ctx, name, metav1.GetOptions{})
	} else {
		_, e = a.kube.RbacV1().RoleBindings(r.Spec.Namespace).Get(ctx, name, metav1.GetOptions{})
	}
	if !apierrors.IsNotFound(e) {
		if e != nil {
			return e
		}
		return errors.New("binding deletion pending")
	}
	return nil
}

func (a *App) reconcile(ctx context.Context, r *Request) error {
	now := a.now()
	if r.terminal(now) {
		if r.Status.Message == "cleanup complete" && !slices.Contains(r.Finalizers, finalizer) {
			if r.DeletionTimestamp == nil && now.Sub(r.CreationTimestamp.Time) > 7*24*time.Hour {
				uid := r.UID
				return a.store.client.Delete(ctx, r.Name, metav1.DeleteOptions{Preconditions: &metav1.Preconditions{UID: &uid}})
			}
			return nil
		}
		if r.Status.Phase != "denied" && r.Status.Phase != "revoked" && r.Status.Phase != "failed" {
			r.Status.Phase = "expired"
		}
		err := a.cleanup(ctx, r)
		r.Status.Message = "cleanup complete"
		if err != nil {
			r.Status.Message = "cleanup pending; early revocation may not have propagated"
		}
		updated, e := a.store.status(ctx, r)
		if e != nil {
			return e
		}
		*r = *updated
		if err != nil {
			return err
		}
		if slices.Contains(r.Finalizers, finalizer) {
			r.Finalizers = slices.DeleteFunc(r.Finalizers, func(f string) bool { return f == finalizer })
			_, e = a.store.update(ctx, r)
		}
		return e
	}
	if r.Status.Deadline == nil {
		return nil
	}
	if err := a.unchanged(ctx, r); err != nil {
		// An unreadable policy must not activate a grant. Existing tokens remain
		// bounded while failed grants are durably revoked and cleaned up.
		r.Status.Phase = "failed"
		r.Status.Message = "policy unavailable or changed"
		updated, e := a.store.status(ctx, r)
		if e != nil {
			return e
		}
		*r = *updated
		return a.reconcile(ctx, r)
	}
	if err := a.ensure(ctx, r); err != nil {
		if errors.Is(err, errGrantChanged) {
			r.Status.Phase = "failed"
			r.Status.Message = errGrantChanged.Error()
			updated, e := a.store.status(ctx, r)
			if e != nil {
				return e
			}
			*r = *updated
			return a.reconcile(ctx, r)
		}
		return err
	}
	r.Status.Phase = "ready"
	r.Status.Message = "approved; credential pickup available"
	_, err := a.store.status(ctx, r)
	return err
}

func (a *App) run(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
	for {
		a.mu.Lock()
		scanCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
		cont := ""
		var errs uint64
		var overdue uint64
		for {
			rs, next, err := a.store.list(scanCtx, 100, cont)
			if err != nil {
				errs++
				slog.Error("request scan failed")
				break
			}
			for _, r := range rs {
				if err = a.reconcile(scanCtx, r); err != nil {
					errs++
					slog.Error("grant reconciliation failed", "request", r.Name)
				}
				if r.Status.Deadline != nil && !a.now().Before(*r.Status.Deadline) && r.Status.Message != "cleanup complete" {
					overdue++
				}
			}
			if next == "" {
				break
			}
			cont = next
		}
		cancel()
		a.reconcileErrors += errs
		a.overdue = overdue
		if errs == 0 {
			a.lastReconcile = a.now()
		}
		a.mu.Unlock()
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

type Credential struct {
	Token      string    `json:"token"`
	Expiration time.Time `json:"expiration"`
	Server     string    `json:"server"`
	CAData     []byte    `json:"caData"`
	TLSName    string    `json:"tlsName,omitempty"`
}

func tokenExpiry(token string) (time.Time, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return time.Time{}, errors.New("invalid token response")
	}
	payload, e := base64.RawURLEncoding.DecodeString(parts[1])
	if e != nil {
		return time.Time{}, errors.New("invalid token response")
	}
	var claims struct {
		Exp int64 `json:"exp"`
	}
	if json.Unmarshal(payload, &claims) != nil || claims.Exp <= 0 {
		return time.Time{}, errors.New("invalid token expiry")
	}
	return time.Unix(claims.Exp, 0).UTC(), nil
}

func (a *App) issue(ctx context.Context, r *Request) (Credential, error) {
	var out Credential
	if r.Status.Deadline == nil || r.terminal(a.now()) {
		return out, errors.New("grant not active")
	}
	if err := a.unchanged(ctx, r); err != nil {
		return out, err
	}
	// Never re-create grant objects in credential pickup: a missing object may
	// represent revocation outside this process.
	if r.Status.Phase != "ready" || r.Status.AccountUID == "" || r.Status.BindingUID == "" {
		return out, errors.New("grant not ready")
	}
	seconds := int64(r.Status.Deadline.Sub(a.now())-a.config.budget()) / int64(time.Second)
	if seconds < 600 {
		return out, errors.New("insufficient approved time remains for a token")
	}
	sa, e := a.kube.CoreV1().ServiceAccounts(a.config.GrantNamespace).Get(ctx, r.grantName(), metav1.GetOptions{})
	if e != nil {
		return out, e
	}
	if sa.UID != r.Status.AccountUID || sa.DeletionTimestamp != nil || sa.Labels[ownership] != string(r.UID) || sa.AutomountServiceAccountToken == nil || *sa.AutomountServiceAccountToken || len(sa.Secrets) != 0 {
		return out, errors.New("grant account changed")
	}
	var binding metav1.Object
	var subjects []rbac.Subject
	var ref rbac.RoleRef
	if r.Spec.Profile.Cluster {
		b, err := a.kube.RbacV1().ClusterRoleBindings().Get(ctx, r.grantName(), metav1.GetOptions{})
		e = err
		binding = b
		if err == nil {
			subjects = b.Subjects
			ref = b.RoleRef
		}
	} else {
		b, err := a.kube.RbacV1().RoleBindings(r.Spec.Namespace).Get(ctx, r.grantName(), metav1.GetOptions{})
		e = err
		binding = b
		if err == nil {
			subjects = b.Subjects
			ref = b.RoleRef
		}
	}
	if e != nil {
		return out, e
	}
	wantSubjects := []rbac.Subject{{Kind: "ServiceAccount", Name: r.grantName(), Namespace: a.config.GrantNamespace}}
	wantRef := rbac.RoleRef{APIGroup: rbac.GroupName, Kind: r.Spec.Profile.Role.Kind, Name: r.Spec.Profile.Role.Name}
	if binding.GetUID() != r.Status.BindingUID || binding.GetDeletionTimestamp() != nil || binding.GetLabels()[ownership] != string(r.UID) || digest(subjects) != digest(wantSubjects) || ref != wantRef {
		return out, errors.New("grant binding changed")
	}
	t, e := a.kube.CoreV1().ServiceAccounts(a.config.GrantNamespace).CreateToken(ctx, r.grantName(), &authv1.TokenRequest{Spec: authv1.TokenRequestSpec{Audiences: []string{a.config.IssuedCredentials.Audience}, ExpirationSeconds: &seconds}}, metav1.CreateOptions{})
	if e != nil {
		return out, e
	}
	exp, e := tokenExpiry(t.Status.Token)
	if e != nil || !a.now().Before(exp) || exp.Add(a.config.budget()).After(*r.Status.Deadline) || t.Status.ExpirationTimestamp.Time.Add(a.config.budget()).After(*r.Status.Deadline) || t.Status.ExpirationTimestamp.IsZero() {
		r.Status.Phase = "failed"
		r.Status.Message = "issued token exceeds approved timing bounds"
		if updated, err := a.store.status(ctx, r); err == nil {
			*r = *updated
			_ = a.reconcile(ctx, r)
		}
		_ = a.cleanup(ctx, r)
		return out, errors.New("token response outside approved timing bounds")
	}
	if r.terminal(a.now()) {
		return out, errors.New("grant expired during issuance")
	}
	r.Status.IssuedExpiry = &exp
	updated, e := a.store.status(ctx, r)
	if e != nil {
		return out, e
	}
	*r = *updated
	slog.Info("grant credential issued", "request", r.Name, "account", r.grantName(), "expires", exp)
	out.Token = t.Status.Token
	out.Expiration = exp
	out.Server = a.config.IssuedCredentials.Server
	out.TLSName = a.config.IssuedCredentials.TLSName
	return out, nil
}

func (a *App) audit(action string, r *Request, i Identity) {
	slog.Info(action, "request", r.Name, "actor_issuer", i.Issuer, "actor_subject", i.Subject, "profile", r.Spec.Profile.Name, "namespace", r.Spec.Namespace, "account", r.grantName())
}
