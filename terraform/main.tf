resource "proxmox_virtual_environment_download_file" "talos_iso" {
  for_each     = toset(var.nodes)
  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key
  file_name    = "talos-${local.talos.version}-metal-amd64-secureboot.iso"
  url          = "https://factory.talos.dev/image/${local.talos.schematic_id}/${local.talos.version}/metal-amd64-secureboot.iso"
}

resource "proxmox_virtual_environment_vm" "k8s_vm" {
  for_each = local.vms_to_create

  name      = "${local.k8s_vm.name_prefix}-${each.value.vm_num}"
  node_name = each.value.node

  stop_on_destroy = true

  agent {
    enabled = true
    trim    = true
    timeout = "5m"
  }

  cpu {
    cores = local.k8s_vm.core_count
    type  = "host"
    numa  = true
  }

  memory {
    dedicated = local.k8s_vm.memory_size
  }

  efi_disk {
    datastore_id      = local.k8s_vm.datastore_id
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  bios    = "ovmf"
  machine = "q35"


  #  initialization {
  #    datastore_id = local.k8s_vm.datastore_id
  #
  #    ip_config {
  #      ipv4 {
  #        address = "dhcp"
  #      }
  #      ipv6 {
  #        address = "dhcp"
  #      }
  #    }
  #
  #    user_account {
  #      username = "talos"
  #      password = "talos"
  #      keys     = [trimspace(data.local_file.ssh_public_key.content)]
  #    }
  #  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = local.k8s_vm.datastore_id
    interface    = "virtio0"
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    size         = local.k8s_vm.disk_size
  }

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_iso[each.value.node].id
  }

  network_device {
    bridge = local.k8s_vm.network_bridge_id
  }

  lifecycle {
    ignore_changes = [
      #      initialization[0].datastore_id,
      #      initialization[0].interface,
      #      network_device[0].disconnected,
      #      network_device[0].mac_address,
      #      disk[0].file_format,
      #      disk[0].file_id,
      #      disk[0].path_in_datastore,
      #      tags,
      #      mac_addresses,
      #      cpu[0].flags,
      id,
      vm_id,
      ipv4_addresses,
      ipv6_addresses
    ]
  }
}

resource "proxmox_virtual_environment_haresource" "k8s_vm_ha" {
  for_each    = proxmox_virtual_environment_vm.k8s_vm
  resource_id = "vm:${each.value.vm_id}"
  state       = "started"
  comment     = "Managed by Terraform"
}

