output "created_vms" {
  value = { for k, vm in proxmox_virtual_environment_vm.k8s_vm :
    vm.name => {
      node = vm.node_name
      id   = vm.id
      ipv4 = one([
        for ip in flatten(vm.ipv4_addresses) : ip
        if(
          # rfc1918
          startswith(ip, "10.") ||
          startswith(ip, "192.168.") ||
          (
            startswith(ip, "172.") &&
            tonumber(split(".", ip)[1]) >= 16 &&
            tonumber(split(".", ip)[1]) <= 31
          )
        )
      ])

      ipv6 = one([
        for ip in flatten(vm.ipv6_addresses) : ip
        if(
          # IPv6 ULA fc00::/7
          startswith(lower(ip), "fc") ||
          startswith(lower(ip), "fd")
        )
      ])
    }
  }
}
