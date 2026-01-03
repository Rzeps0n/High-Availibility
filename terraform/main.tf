variable "vm_count" {
  type    = number
  default = 9
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

locals {
  vms_to_create = {
    for idx in range(var.vm_count) :
    idx => {
      vm_num         = idx + 1
      node_idx       = idx % length(var.nodes)
      node           = var.nodes[idx % length(var.nodes)]
      vm_idx_on_node = floor(idx / length(var.nodes))
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
resource "proxmox_virtual_environment_vm" "k8s_vm" {
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
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    size         = 16
  }

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      #      initialization[0].datastore_id,
      #      initialization[0].interface,
      #      network_device[0].disconnected,
      #      network_device[0].mac_address,
      disk[0].file_format,
      #      disk[0].file_id,
      #      disk[0].path_in_datastore,
      #      tags,
      #      mac_addresses,
      id,
      vm_id,
      #      cpu[0].flags,
      ipv4_addresses,
      ipv6_addresses
    ]
  }
}
