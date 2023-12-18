# Stacks - Central repo for everything GitOps

Hello and welcome to my homelab. I use this place to pratice DevOps concepts and for hosting simple functional services at home. 

Here you'll find:
- Terraform and Ansible provisioning for a k3s cluster on Proxmox
- Kubernetes deployments for essential servies like MetalLB and Mosquitto
- Docker for non-critical applications

## General Flow

### Core

The core components of the cluster

K3S - Lightweight Kubernetes

Traefik - Kubernetes Ingress Controller

Helm - Kubernetes Package Manager

Terraform - VM Provisioning

Ansible - Configuration management and updates

Portainer - GitOps workflow for Docker IaC

Proxmox - Clustered Hypervisor for LXCs, VMs, and Kubernetes Management and Worker Nodes
