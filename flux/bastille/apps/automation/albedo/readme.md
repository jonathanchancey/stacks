# albedo

the browser route uses envoy oidc with the kaniop-managed client in
[`identity/oauth.yaml`](identity/oauth.yaml). only members of `albedo-users` receive the
required scopes. edit the membership with
`sops identity/group.sops.yaml` from this directory; keep usernames encrypted.
kaniop creates the client credential secret at runtime, outside sops.
the app waits for the group and client to be ready before publishing its route.

the web proxy in [`app/resources`](app/resources) forwards to albedo's loopback
listener, keeping its browser key inside the pod. it checks the public origin
before forwarding api requests and leaves artifact sandbox headers intact.
only the edge gateway can reach its service. this grants access to the shared
albedo instance; it does not create separate user workspaces.

after rotating albedo's browser link, restart the deployment so the proxy loads
the new key. keep the home volume private and preserve it during recovery.
