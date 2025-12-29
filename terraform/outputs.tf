output "created_vms" {
  value = { for k, vm in proxmox_virtual_environment_vm.ubuntu_vm :
    vm.name => {
      node = vm.node_name
      id   = vm.id
    }
  }
}
