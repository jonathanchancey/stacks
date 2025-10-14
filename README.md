# Stacks

Welcome to my personal waste of electricity

I use this repo to define services I'd rather not live without

## Clusters

### Academy - K3s/Ansible/Terraform

The cluster that started it all

> though it's getting a bit creaky at over 730 days

- 7 nodes, 40 cores, 154GB RAM
- running on mixed architecture
- scheduled for decommission

### Bastille - Talos/Bare Metal

Nascent production cluster following best practices (slightly more than what's sensible)

> if it's not in flux, if it ain't real

- 3 nodes, 48 cores, 96GB DDR5 (non ecc)
- ceph block storage with thunderbolt networking ~23Gbps
- cloudnative-pg with openEBS localpv on NVME, streaming WAL to b2
- Cilium CNI, BGP, 2.5Gb networking (10Gb soon)

## Folder Structure

- **Ansible** (`ansible/`) - Maintenance and Configuration
- **Flux** (`flux/`) - GitOps manifests organized by cluster
- **Terraform** (`terraform/`) - VM provisioning and DNS management
- **Tools** (`tools/`) - Scripts, templates, taskfiles

## Dec 2023

### Proxmox Cluster

<table align="center">
  <tr>
  <td>12u Rack</td>
  <td>Explanation</td>
  </tr>
  <tr>
    <td><img src="https://github.com/jonathanchancey/assets/blob/main/images/rack2.jpg?raw=true" width=330 alt="A 16U server rack"></td>
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
