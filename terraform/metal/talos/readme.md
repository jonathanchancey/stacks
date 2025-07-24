# talos

Getting the kubeconfig and talosconfig for this cluster can be done with

```bash
terraform output -raw kubeconfig > kubeconfig
terraform output -raw talosconfig > talosconfig
```

i915.enable_guc=3 intel_iommu=on iommu=pt mitigations=off net.ifnames=0 -selinux=0 apparmor=0 init_on_alloc=0 init_on_free=0 security=none talos.auditd.disabled=1
https://factory.talos.dev/?arch=amd64&cmdline=i915.enable_guc%3D3+intel_iommu%3Don+iommu%3Dpt+mitigations%3Doff+net.ifnames%3D0+-selinux%3D0+apparmor%3D0+init_on_alloc%3D0+init_on_free%3D0+security%3Dnone+talos.auditd.disabled%3D1&cmdline-set=true&extensions=-&extensions=siderolabs%2Fdrbd&extensions=siderolabs%2Fi915&extensions=siderolabs%2Fintel-ucode&extensions=siderolabs%2Fthunderbolt&extensions=siderolabs%2Futil-linux-tools&platform=metal&target=metal&version=1.10.4

factory.talos.dev/metal-installer/5189cca21c5ab3eb5519ef19b5084b4dbd5d1ba87a6170d99ce23e3e318138da:v1.10.4



# basic manual process

```bash
talosctl -n 10.131.181.87 upgrade --image factory.talos.dev/metal-installer/383176e2d75a9760ae4026be245113e2fce56e397eb8dcf72dcf1889f9fdc334:v1.10.3
talosctl -n 10.131.181.86 upgrade --image factory.talos.dev/metal-installer/383176e2d75a9760ae4026be245113e2fce56e397eb8dcf72dcf1889f9fdc334:v1.10.3
talosctl -n 10.131.181.83 upgrade --image factory.talos.dev/metal-installer/383176e2d75a9760ae4026be245113e2fce56e397eb8dcf72dcf1889f9fdc334:v1.10.3
```

Talos Linux Image Factory
The Talos Linux Image Factory, developed by Sidero Labs, Inc., offers a method to download various boot assets for Talos Linux.

For more information about the Image Factory API and the available image formats, please visit the GitHub repository.

Version: v0.7.3

Loading...
Schematic Ready
Your image schematic ID is: c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df
customization:
    extraKernelArgs:
        - i915.enable_guc=3
        - intel_iommu=on
        - iommu=pt
        - mitigations=off
        - net.ifnames=0
    systemExtensions:
        officialExtensions:
            - siderolabs/i915
            - siderolabs/intel-ucode
            - siderolabs/thunderbolt
            - siderolabs/util-linux-tools
First Boot
Here are the options for the initial boot of Talos Linux on a bare-metal machine or a generic virtual machine:

ISO
https://factory.talos.dev/image/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/metal-amd64.iso (ISO documentation)
Disk Image (raw)
https://factory.talos.dev/image/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/metal-amd64.raw.zst
Disk Image (qcow2)
https://factory.talos.dev/image/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/metal-amd64.qcow2
PXE boot (iPXE script)
https://pxe.factory.talos.dev/pxe/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/metal-amd64
(PXE documentation)
Initial Installation
For the initial installation of Talos Linux (not applicable for disk image boot), add the following installer image to the machine configuration:
factory.talos.dev/metal-installer/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df:v1.10.3

Upgrading Talos Linux
To upgrade Talos Linux on the machine, use the following image:
factory.talos.dev/metal-installer/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df:v1.10.3

Documentation
What's New in Talos v1.10
Support Matrix for v1.10
Getting Started Guide
Bare-metal Network Configuration
Production Cluster Guide
Troubleshooting Guide
Extra Assets
Kernel Image
https://factory.talos.dev/image/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/kernel-amd64
Kernel Command Line
https://factory.talos.dev/image/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/cmdline-metal-amd64
Initramfs Image
https://factory.talos.dev/image/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/initramfs-amd64.xz
UKI
https://factory.talos.dev/image/c30695b318c025ad3cabdb0fc1a82847c570f2321d9bc450336dc71d996bc2df/v1.10.3/metal-amd64-uki.efi