# Stacks

Hello and welcome to my homelab. I use this place to practice DevOps concepts and for hosting simple functional services at home.

## General Flow

### Platforms

Proxmox - Clustered Hypervisor for Kubernetes, Docker, Ceph, LXCs, and VMs

K3S - Lightweight Kubernetes for Internal Services

RKE2 - Secure Kubernetes for External Services

### Automation

Terraform - Proxmox Provisioning

Ansible - Configuration management

### Services

Rancher - Enterprise Kubernetes management

Portainer - GitOps workflow for Docker IaC

Many more!

## Proxmox Cluster

<table align="center">
  <tr>
  <td>12u Rack</td>
  <td>Explanation</td>
  </tr>
  <tr>
    <td><img src="https://github.com/jonathanchancey/assets/blob/main/images/rack2.jpg?raw=true" width=330></td>
    <td>
    <table align="center">
  <tr>
    <td>24p patch panel</td>
  </tr>
  <tr>
    <td>Mikrotik 24p switch</td>
  </tr>
  <tr>
    <td>Shelf w/ 2.5g switch & EQ12</td>
  </tr>
  <tr>
    <td>Cable Brush</td>
  </tr>
  <tr>
    <td>PDU 6+6 outlet</td>
  </tr>
  <tr>
    <td>3u shelf w/</td>
  </tr>
  <tr>
    <td>6x8TB external HDDs</td>
  </tr>
  <tr>
    <td>EQ12 and NA7B</td>
  </tr>
  <tr>
    <td>Sliger CX3701 NAS w/</td>
  </tr>
  <tr>
    <td>2x8TB, 12TB, and 14TB HDDs</td>
  </tr>
  <tr>
    <td>1TB NVME ZFS mirror</td>
  </tr>
  <tr>
    <td>1u 2xE5645 Supermicro </td>
  </tr>
</table>
    </td>
  </tr>
 </table>


### Topology

```yaml
- forest # nas
  - LXC/VMs
    - reap # machinaris harvestor
    - acolyte-00 # k3s server VM
    - sentinel-00 # RKE2 server VM
  - storage
    - foxes # 1TB NVME ZFS mirror
    - 6x8TB ext4 external drives # Chia
    - hydra # 8TB ceph OSD
- lich # compute
  - LXC/VMs
    - beholder # frigate VLAN 50 and iGPU docker host
    - acolyte-01 # k3s server VM
    - neophyte-01 # k3s agent VM
    - sentinel-01 # RKE2 server VM
    - cavalier-01 # RKE2 agent VM
  - storage
    - hydra # 8TB ceph OSD
- okapi # compute and nas
  - LXC/VMs
    - chicken # NAS
    - salamander # discord bot
    - fish # primary docker node
    - acolyte-02 # k3s server VM
    - neophyte-02 # k3s agent VM
    - cavalier-02 # RKE2 agent VM
  - storage
    - strawberry # ZFS 24TB RAIDZ1 3x12TB
    - hydra # 8TB ceph OSD
- shar # router
  - LXC/VMs
    - loss # DNS, DHCP for 10.10.0.1/24
    - dread # OPNsense VM
- selune # compute
  - LXC/VMs
    - sentinel-02 # RKE2 server VM
    - unused # OPNsense failover
```

![proxmox-small](https://github.com/jonathanchancey/assets/blob/main/images/proxmox-small.png?raw=true)
