# Stacks

Welcome to my *contemplection*[^1]

## Bastille - HomeProd Cluster

Talos on Bare Metal

> not in flux == not real

- 3 nodes, 48 cores, 96GB DDR5
- Ceph block storage with Thunderbolt networking ~23Gbps
- CloudNative-PG with openEBS localpv on NVME, streaming WAL to B2
- Cilium CNI, BGP, 2.5Gb networking

## Folder Structure

- `flux/` - Kubernetes resources, Talos and Flux configs
- `tools/` - scripts, taskfiles, archive

## The Humble Rack

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
    <td>24p Mikrotik switch</td>
  </tr>
  <tr>
    <td>2.5g unmanaged switch & EQ12</td>
  </tr>
  <tr>
    <td>Cable Brush</td>
  </tr>
  <tr>
    <td>12p PDU</td>
  </tr>
  <tr>
    <td>6x 8TB Drives</td>
  </tr>
  <tr>
    <td>EQ12 & NA7B</td>
  </tr>
  <tr>
    <td>-</td>
  </tr>
  <tr>
    <td>Sliger CX3701 N100 NAS</td>
  </tr>
  <tr>
    <td>-</td>
  </tr>
  <tr>
    <td>-</td>
  </tr>
  <tr>
    <td>Dual Socket E5645 Supermicro</td>
  </tr>
</table>
    </td>
  </tr>
 </table>

![proxmox-small](https://github.com/jonathanchancey/assets/blob/main/images/proxmox-small.png?raw=true)

[^1]: **contemplection**, a portmanteau of *contemplation* and *complection* (see complect[^2])
[^2]: **complect**, woven together or interwoven [Simple Made Easy (Rich Hickey)](https://www.infoq.com/presentations/Simple-Made-Easy/)
