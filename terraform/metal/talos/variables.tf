variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "talos_version" {
  description = "The version for the Talos cluster"
  type = string
}

variable "schematic_id" {
  description = "The schematic id for the Talos cluster"
  type = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
}

variable "node_data" {
  description = "A map of node data"
  type = object({
    controlplanes = map(object({
      install_disk = string
      hostname     = optional(string)
    }))
    workers = map(object({
      install_disk = string
      hostname     = optional(string)
    }))
  })
}
