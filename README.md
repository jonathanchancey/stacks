# Stacks

Welcome to my _contemplection_[^1]

## Bastille Cluster

Talos on Bare Metal

> not in flux == not real

- 3 nodes, 48 cores, 96GB DDR5
- Ceph block storage with Thunderbolt networking ~23Gbps
- CloudNative-PG with openEBS localpv on NVME, streaming WAL to B2
- Cilium CNI, BGP, 2.5Gb networking

## Folder Structure

- `flux/` - Kubernetes resources, Talos and Flux configs
- `tools/` - scripts, taskfiles, archive

## Development shell

With Nix and flakes enabled, run `nix develop` from any repository directory.
The [flake](flake.nix) provides Git, Task, and git-of-theseus on Apple Silicon
macOS and ARM/x86 Linux. Dependencies are pinned by `flake.lock`; the first run
may need to download or build them.

Add tools to the shell's `packages` list in [flake.nix](flake.nix). For tools
outside nixpkgs, follow the [git-of-theseus package](tools/nix/git-of-theseus.nix).
Use `nix fmt` to format the Nix files and `nix flake check` to build and check
the tools. Update nixpkgs with `nix flake update nixpkgs`, then check and commit
`flake.lock`.

The shell's toolset grows incrementally. Other repository tasks still need their
existing dependencies; Flux tasks continue to use `tools/.venv`.

### Repository history

[git-of-theseus](https://github.com/erikbern/git-of-theseus) analyzes committed
history and plots how much code survives from each year:

```sh
task theseus:all                 # Analyze all filetypes, then plot
task theseus:analyze-all         # Analyze all filetypes only
task theseus:analyze-extensions  # Analyze yaml,yml,sh,py,tf,j2,json5,toml,cfg
task theseus:analyze             # Analyze upstream's default code filetypes
task theseus:plot                # Plot existing cohorts.json
```

Results go to ignored `.theseus/`, including `cohorts.json` and `stack_plot.png`.
Each analysis overwrites the previous results; set `OUTDIR=.theseus/all` (or
another directory) on both the analysis and plot tasks to keep separate runs.
Pass extra options after `--`, for example `task theseus:analyze-all -- --procs 4`.

The default filetypes exclude YAML; use `analyze-all` or `analyze-extensions` to
include it.

## Screenshots

![homepage](https://github.com/jonathanchancey/assets/blob/main/images/home-chancey-dev-2026-07-29-1704.png?raw=true)

### The Humble Rack

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

[^1]: **contemplection**, a portmanteau of _contemplation_ and _complection_ (see complect[^2])

[^2]: **complect**, woven together or interwoven [Simple Made Easy (Rich Hickey)](https://www.infoq.com/presentations/Simple-Made-Easy/)
