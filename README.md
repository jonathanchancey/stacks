# Stacks

Welcome to my personal waste of electricity

I use this repo to practice DevOps concepts for services I'd rather not live without

## Folder Structure

### Ansible - `ansible`

Bare metal configuration

### Flux - `flux`

My GitOps project of choice

### Kubernetes Clusters - `k8s`

~~I'm heavily invested in k3s due to Raspberry Pi and SBC compatibility but it would be nice to jump to Talos when support arrives~~

Switched off random SBCs to mini PCs for Talos and it's been consistently amazing. Besides using CM3588s have only taught me lessons in disaster recovery

#### Academy - K3s

The cluster that started it all. Currently production but it's getting a bit creaky at 656d+

7 nodes, 40 cores (28 qemu64, 12 arm64), 154GB RAM
- ~~3 masters~~ 1 master
- 5 workers, three of which are CM3588s primarily for Longhorn

#### Bastille - Talos

Nascent production cluster with enforced best practices running on 3 MS-01s

- 3 nodes, 48 cores, 96 GB DDR5 RAM
- Thunderbolt ring networking
- 2.5Gb connection on SERVERS vlan

#### Coalesce and Dichotomy - K3s

Cilium Cluster Mesh and multi-zone testing

#### Ephemera - K3s

Test cluster for major changes like swapping out the CNI and switching to BGP

### Terraform - `terraform`

For DNS and VM Provisioning

### Proxmox

Hypervisor of choice

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


![proxmox-small](https://github.com/jonathanchancey/assets/blob/main/images/proxmox-small.png?raw=true)
