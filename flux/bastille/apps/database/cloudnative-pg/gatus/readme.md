# gatus database

[`database.yaml`](database.yaml) manages the `gatus` database and login role on
`bastille-pg`. the `cloudnative-pg-gatus` flux kustomization waits for both
resources to report the current generation applied before gatus can reconcile.
application tables and migrations remain gatus's responsibility.

## adopting an existing database

before applying, confirm that `INIT_POSTGRES_DBNAME` and `INIT_POSTGRES_USER` in
gatus's encrypted application secret are both `gatus`, and that its host points
to `bastille-pg`. inspect the existing database with an administrative connection:

```sql
select datname, pg_get_userbyid(datdba) as owner
from pg_database where datname = 'gatus';
select rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole,
       rolreplication, rolbypassrls, rolinherit, rolconnlimit, rolvaliduntil
from pg_roles where rolname = 'gatus';
select parent.rolname as membership
from pg_auth_members m
join pg_roles child on child.oid = m.member
join pg_roles parent on parent.oid = m.roleid
where child.rolname = 'gatus';
```

the manifest assumes the database is already owned by `gatus`, with a login role
using ordinary non-superuser defaults, no parent memberships, no connection limit,
and no password expiry. adoption changes ownership and role attributes to match
the manifest; it does not reassign existing tables or revoke direct object grants.
if the existing configuration differs, resolve that difference before adoption.

## credentials and recovery

the role intentionally omits `passwordSecret` and `disablePassword`, preserving
its existing password. gatus continues reading its application secret; cnpg does
not rotate or restore that password. a new role has no password: after recovery
into a fresh cluster, provision the matching password before starting gatus.
the unused encrypted `INIT_POSTGRES_SUPER_PASS` entry can be removed when the
application secret is next edited with sops; it is no longer injected into a pod.

both reclaim policies are `retain`, so removing the kubernetes resources leaves
the sql database and role intact. this does not prevent explicit destructive
configuration such as `Database.spec.ensure: absent`. reverting to the previous
init container does not undo ownership or role-attribute changes from adoption.
