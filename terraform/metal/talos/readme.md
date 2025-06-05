# talos

Getting the kubeconfig and talosconfig for this cluster can be done with

```bash
terraform output -raw kubeconfig > kubeconfig
terraform output -raw talosconfig > talosconfig
```
