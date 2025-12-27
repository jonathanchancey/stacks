# Stacks

Welcome to my *contemplection*

## Clusters

### Bastille - Talos/Bare Metal

Production cluster following best practices (slightly more than what's sensible)

> not in flux == not real

- 3 nodes, 48 cores, 96GB DDR5 (non ecc)
- Ceph block storage with Thunderbolt networking ~23Gbps
- CloudNative-PG with openEBS localpv on NVME, streaming WAL to B2
- Cilium CNI, BGP, 2.5Gb networking

### Academy - K3s/Ansible/Terraform

The cluster that started it all

> though it's getting a bit creaky at over 800 days

- 7 nodes, 40 cores, 154GB RAM
- mixed architecture
- scheduled for decommission
- ~~will rise again~~ it most certainly will not

## Folder Structure

- `ansible/` - maintenance and configuration
- `flux/` - Talos configs and everything Kubernetes
- `terraform/` - VM provisioning and DNS management
- `tools/` - scripts, templates, taskfiles

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
