# Stacks

Welcome to my personal waste of electricity

I use this repo to practice DevOps concepts for services I'd rather not live without

## Architecture

GitOps-driven infrastructure using Flux v2 for continuous deployment across multiple Kubernetes clusters.

### Components

- **Ansible** (`ansible/`) - Bare metal configuration and provisioning
- **Flux** (`flux/`) - GitOps manifests organized by cluster
- **Terraform** (`terraform/`) - VM provisioning and DNS management
- **Tools** -(`tools/`) Scripts and taskfiles

### Clusters

#### Academy - K3s
The cluster that started it all. Currently "production" but it's getting a bit creaky at over 700 days
- 7 nodes, 40 cores, 154GB RAM
- running on mixed architecture
- Scheduled for decommission

#### Bastille - Talos
Nascent production cluster following strict best practices
- 3 nodes, 48 cores, 96GB DDR5
- ceph storage, cloudnative-pg on NVME, Cilium CNI
- thunderbolt networking ~23Gbps and 2.5Gb networking

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
