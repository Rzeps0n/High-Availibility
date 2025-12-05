terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.88.0"
    }
  }
}
provider "proxmox" {
  endpoint  = var.proxmox_ve_endpoint
  api_token = var.proxmox_ve_api_token
  insecure  = true
  ssh {
    agent       = false
    username    = "root"
    private_key = file("~/.ssh/id_ed25519")
    node {
      name    = "dl380-1"
      address = "dl380-1.internal"
    }
    node {
      name    = "dl380-2"
      address = "dl380-2.internal"
    }
    node {
      name    = "dl380-3"
      address = "dl380-3.internal"
    }
  }
}
