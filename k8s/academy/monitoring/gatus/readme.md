# gatus

```bash
kubectl create ns monitoring
kubens monitoring
helm repo add minicloudlabs https://minicloudlabs.github.io/helm-charts
helm repo add twin https://twin.github.io/helm-charts
helm repo update
helm upgrade --install gatus -n monitoring -f values.yaml -f values-secrets.yaml twin/gatus --reset-values
```

## parse_homepage

`parse_homepage.yaml` is a quick script that turns a file that looks like this

```
- Proxmox:
    href: https://proxmox.fkn.chancey.dev
    icon: proxmox.png
    description: Hypervisor
- Portainer:
    href: https://portainer.fkn.chancey.dev
    icon: portainer.png
    description: Docker Management
```

into a file that looks like this

```
- name: Proxmox
  url: https://proxmox.fkn.chancey.dev
  conditions:
  - '[STATUS] == 200'
- name: Portainer
  url: https://portainer.fkn.chancey.dev
  conditions:
  - '[STATUS] == 200'
```

use it like this

```bash
./parse_homepage input.yaml > output.yaml
```
