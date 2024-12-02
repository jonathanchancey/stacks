# Stacks

Hello and welcome to my homelab. I use this place to practice DevOps concepts and for hosting simple functional services at home.

## Structure

### Ansible - `ansible`

Bare Metal Provisioning and Configuration management

### Flux - `flux`

GitOps, used to be fleet but so far flux is lovely

### Kubernetes Clusters - `k8s`

I'm heavily invested in k3s due to Raspberry Pi and SBC compatibility but it would be nice to jump to talos when support gets better.

#### Academy - K3s

My production cluster, adopting nodes and moving towards best practices slowly but surely

9 nodes, 44 cores (32 qemu64, 12 arm64), 144GiB RAM
- 3 master
- 5 workers, three of which are cm3588s for longhorn

#### Bastille - RKE2

For External Services

#### Coalesce and Dichotomy - K3s

Cilium Cluster Mesh and multi zone testing

### Terraform - `terraform`

I use terraform for local/public DNS and for "Quick" VM Provisioning

Proxmox really isn't suited for terraform but I'm excited to try VMs in kubernetes or maybe that popsicle operator (crossplane)

### Proxmox

Clustered Hypervisor for Kubernetes, Docker, ~~Ceph (someday we will return)~~, LXCs, and VMs

## Dec 2023

### Proxmox Cluster

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
