variable "proxmox_api_url" {
  type = string
}

variable "proxmox_user" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "target_node" {
  type        = string
  description = "Proxmox target node"
}

variable "hostname" {
  type        = string
  description = "Specifies the host name of the container."
}

variable "description" {
  type        = string
  description = "LXC description"
  default     = "kubernetes"
}

variable "ostemplate" {
  type        = string
  description = "Path to LXC template. (e.g. local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz)"
}

variable "password" {
  type        = string
  description = "LXC password"
}

variable "unprivileged" {
  type        = bool
  description = "Enable unpriviledged"
  default     = true
}

variable "cores" {
  type        = number
  description = "CPU cores for Proxmox LXC"
  default     = 4
}

variable "memory" {
  type        = number
  description = "Memory size for Proxmox LXC in MB"
  default     = 2048
}

variable "onboot" {
  type        = bool
  description = "Start on host boot"
  default     = true
}

variable "features_fuse" {
  type        = bool
  description = "Enable fuse"
  default     = false
}

variable "features_nesting" {
  type        = bool
  description = "Enable nesting"
  default     = false
}

variable "features_mount" {
  type        = string
  description = "Example string: nfs;cifs"
  default     = ""
}

variable "rootfs_storage" {
  type        = string
  description = "Name of rootfs storage"
}

variable "rootfs_storage" {
  type        = string
  description = "Size of volume to create"
  default     = "32G"
}

variable "network_name" {
  type        = string
  description = "The name of the network interface as seen from inside the container (e.g. eth0)."
  default     = "eth0"
}

variable "network_bridge" {
  type        = string
  description = " The bridge to attach the network interface to (e.g. vmbr0)."
  default     = "vmbr0"
}

variable "network_ip" {
  type        = string
  description = "The IPv4 address of the network interface. Can be a static IPv4 address (in CIDR notation), dhcp, or manual."
  default     = "dhcp"
}

variable "bind_mountpoint_slot" {
  type        = string
  description = "Mountpoint slot"
  default     = "0"
}

variable "bind_mountpoint_storage" {
  type        = string
  description = "Host storage path"
  default     = "dhcp"
}

variable "bind_mountpoint_mp" {
  type        = string
  description = "Conatiner storage path"
  default     = "dhcp"
}

variable "bind_mountpoint_size" {
  type        = string
  description = ""
  default     = "dhcp"
}

variable "ssh_public_keys" {
  # type        = string
  description = "Multi-line string of SSH public keys that will be added to the container. Can be defined using heredoc syntax."
  default = ""
}
