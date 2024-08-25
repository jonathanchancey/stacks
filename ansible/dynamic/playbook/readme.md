# dynamic

## example with `../../../terraform/vm/pocket`

```bash
ansible-inventory -i inventory/nodes/hosts.yml --graph
```

```log
@all:
  |--@ungrouped:
  |--@k8s_cluster:
  |  |--@kube_control_plane:
  |  |  |--pocket
  |  |--@kube_node:
  |  |  |--turn
  |--@debian:
  |  |--pocket
  |  |--turn
```

```bash
ansible -e "ansible_user=ansible" -i inventory/nodes/hosts.yml -m ping all
```

```log
pocket | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.11"
    },
    "changed": false,
    "ping": "pong"
}
turn | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.11"
    },
    "changed": false,
    "ping": "pong"
}
```
