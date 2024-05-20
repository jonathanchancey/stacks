# longhorn

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook main.yml --user napkin -i inventory/hosts
```

## taints and tolerations

[**Longhorn documentation**](https://longhorn.io/docs/1.6.0/advanced-resources/deploy/taint-toleration/#setting-up-taints-and-tolerations-during-installing-longhorn)

If need be, change the taint to match your master nodes `roles/longhorn/files/longhorn.yaml` or later in the longhorn gui.

under `longhorn-driver-deployer` and `longhorn-manager`
```yaml
tolerations:
- key: "node-role.kubernetes.io/master"
  operator: "Exists"
  effect: "NoSchedule"
```

> note: it is also important to set tolerations for system-managed components like Instance Manager, CSI Driver, and Engine images.
