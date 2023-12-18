# Stacks - Central repo for everything GitOps

Hello and welcome to my homelab. I use this place to pratice DevOps concepts and for hosting simple functional services at home. 

Here you'll find:
- Terraform and Ansible provisioning for a k3s cluster on Proxmox
- Kubernetes deployments for essential servies like MetalLB and Mosquitto
- Docker for non-critical applications

## General Flow

### Core

The core components of the cluster

K3S - Lightweight Kubernetes

Traefik - Kubernetes Ingress Controller

Helm - Kubernetes Package Manager

Terraform - VM Provisioning

Ansible - Configuration management and updates

Portainer - GitOps workflow for Docker IaC

Proxmox - Clustered Hypervisor for LXCs, VMs, and Kubernetes Management and Worker Nodes

## Proxmox Cluster

### Topology

```yaml
- shar
  - LXC/VMs
    - loss # pihole DNS, DHCP for 10.10.0.1/24
    - dread # OPNsense VM
  - storage
    - 512GB nvme # boot
- selune
  - LXC/VMs
    - unused # OPNsense failover
  - storage
    - 512GB nvme # boot
- forest
  - LXC/VMs
    - reap # machinaris harvestor
    - acolyte-00 # k8s control VM
    - neophyte-00 # k8s agent VM
  - storage
    - 120GB Kingston # boot
    - foxes # 1TB NVME ZFS mirror
    - 6x8TB ext4 external drives # Chia
    - cow # WGG 8WG degraded ZFS
- lich
  - LXC/VMs
    - sever # docker node
    - beholder # frigate VLAD 50 
    - acolyte-01 # k8s control VM
    - neophyte-01 # k8s agent VM
  - storage
    - 512GB nvme # boot
- okapi
  - LXC/VMs
    - chicken # NAS
      - Samba shares
      - Identities
    - salamander # discord bot
    - fish # main docker node
      - media
        - jellyfin
        - navidrome
      - home
        - syncthing
        - homeassistant
        - homepage
      - services
        - uptime kuma
        - syncthing
        - freshrss
        - machinaris
        - watchtower
    - lion # okapi vlan testing 
    - acolyte-02 # k8s control VM
    - neophyte-02 # k8s agent VM
  - storage
    - 120GB Kingston # boot
    - strawberry # ZFS 24TB RAIDZ1 3x12TB
```
