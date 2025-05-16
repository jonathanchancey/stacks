# Stacks

Welcome to my personal waste of electricity

I use this repo to practice DevOps concepts for services I'd rather not live without

## Folder Structure

### Ansible - `ansible`

Bare metal configuration

### Flux - `flux`
 
My GitOps project of choice

### Kubernetes Clusters - `k8s`

I'm heavily invested in k3s due to Raspberry Pi and SBC compatibility but it would be nice to jump to Talos when support arrives

#### Academy - K3s

My production cluster. Moving towards home-viable best practices slowly but surely

7 nodes, 40 cores (28 qemu64, 12 arm64), 144GiB RAM
- ~~3 masters~~ 1 master
- 5 workers, three of which are cm3588s primarily for longhorn

#### Bastille - RKE2

For External Services

#### Coalesce and Dichotomy - K3s

Cilium Cluster Mesh and multi-zone testing

#### Ephemera - K3s

Test cluster for Academy. Used to test major changes like swapping out the CNI and switching to BGP

### Terraform - `terraform`

For DNS and VM Provisioning

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


![proxmox-small](https://github.com/jonathanchancey/assets/blob/main/images/proxmox-small.png?raw=true)
