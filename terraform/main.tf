# Variables (same as above)
variable "vm_count_per_node" {
  type    = number
  default = 1
}

variable "nodes" {
  type    = list(string)
  default = ["dl380-1", "dl380-2", "dl380-3"]
}

variable "base_vm_name" {
  type    = string
  default = "terraform-pve-test"
}

data "local_file" "ssh_public_key" {
  filename = pathexpand("~/.ssh/id_ed25519.pub")
}

# Create a map of all VMs to create
locals {
  vms_to_create = { for idx in range(0, var.vm_count_per_node * length(var.nodes)) :
    idx => {
      node_idx       = floor(idx / var.vm_count_per_node)
      node           = var.nodes[floor(idx / var.vm_count_per_node)]
      vm_num         = idx + 1
      vm_idx_on_node = idx % var.vm_count_per_node
    }
  }
}

# Download Ubuntu cloud image on each node
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  for_each = toset(var.nodes)

  content_type = "import"
  datastore_id = "local"
  node_name    = each.key
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  file_name    = "jammy-server-cloudimg-amd64.qcow2"
}

# Create VMs using for_each
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  for_each = local.vms_to_create

  name      = "${var.base_vm_name}-${each.value.vm_num}"
  node_name = each.value.node

  stop_on_destroy = true

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  initialization {
    datastore_id = "linstor_storage"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "ubuntu"
      password = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  disk {
    datastore_id = "linstor_storage"
    import_from  = proxmox_virtual_environment_download_file.ubuntu_cloud_image[each.value.node].id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 8
  }

  network_device {
    bridge = "vmbr0"
  }
}
