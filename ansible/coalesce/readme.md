# RKE2 Coalesce Ansible

openSUSE Leap 15.6 with RKE2 1.30 and Rancher v2.9.1

https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-9-1/

```bash
ansible -e "ansible_user=ansible" -m ping kube_control_plane
```

```bash
ansible-playbook main.yml
```
