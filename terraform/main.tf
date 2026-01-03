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
  default = "terraform-talos"
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

locals {
  talos = {
    version = "v1.12.0"
  }
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  for_each     = toset(var.nodes)
  content_type = "import"
  datastore_id = "local"
  node_name    = each.key
  file_name    = "talos-${local.talos.version}-nocloud-amd64.qcow2"
  url          = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/${local.talos.version}/metal-amd64-secureboot.qcow2"
#  url          = "https://factory.talos.dev/image/583560d413df7502f15f3c274c36fc23ce1af48cef89e98b1e563fb49127606e/${local.talos.version}/nocloud-amd64.qcow2"
}

# Create VMs using for_each
resource "proxmox_virtual_environment_vm" "talos_vm" {
  for_each = local.vms_to_create

  name      = "${var.base_vm_name}-${each.value.vm_num}"
  node_name = each.value.node

  stop_on_destroy = true

  agent {
    enabled = true
    trim    = true
    timeout = "5m"
  }

  cpu {
    cores = 2
    type  = "host"
    numa  = true
  }

  memory {
    dedicated = 2048
  }

  efi_disk {
    datastore_id      = "linstor_storage"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  bios    = "ovmf"
  machine = "q35"


  initialization {
    datastore_id = "linstor_storage"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "dhcp"
      }
    }

    user_account {
      username = "talos"
      password = "talos"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = "linstor_storage"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image[each.value.node].id
    interface    = "virtio0"
    file_format  = "qcow2"
    iothread     = true
    discard      = "on"
    size         = 16
  }

  network_device {
    bridge = "vmbr0"
  }
}
