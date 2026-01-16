#locals {
#  vm_ipv4_map = {
#    for k, vm in proxmox_virtual_environment_vm.k8s_vm :
#    k => one([
#      for ip in flatten(vm.ipv4_addresses) : ip
#      if(
#        startswith(ip, "10.") ||
#        startswith(ip, "192.168.") ||
#        (
#          startswith(ip, "172.") &&
#          tonumber(split(".", ip)[1]) >= 16 &&
#          tonumber(split(".", ip)[1]) <= 31
#        )
#      )
#    ])
#  }
#
#  # Control-plane: 1,4,7,10,...
#  control_plane_vms = {
#    for k, ip in local.vm_ipv4_map :
#    k => { ip = ip }
#    if((k) % 3 == 0)
#  }
#
#  worker_vms = {
#    for k, ip in local.vm_ipv4_map :
#    k => { ip = ip }
#    if((k) % 3 != 0)
#  }
#
#  control_plane_node_ips = [for v in local.control_plane_vms : v.ip]
#  worker_node_ips        = [for v in local.worker_vms : v.ip]
#
#  cluster_endpoint_ip = local.control_plane_node_ips[0]
#}
#
#resource "talos_machine_secrets" "this" {}
#
#data "talos_client_configuration" "this" {
#  cluster_name         = "terraform-talos"
#  client_configuration = talos_machine_secrets.this.client_configuration
#  endpoints            = local.control_plane_node_ips
#}
#
#data "talos_machine_configuration" "control_plane" {
#  for_each         = local.control_plane_vms
#  cluster_name     = "terraform-talos"
#  cluster_endpoint = "https://${local.cluster_endpoint_ip}:6443"
#  machine_type     = "controlplane"
#  machine_secrets  = talos_machine_secrets.this.machine_secrets
#}
#
#data "talos_machine_configuration" "worker" {
#  cluster_name     = "terraform-talos"
#  cluster_endpoint = "https://${local.cluster_endpoint_ip}:6443"
#  machine_type     = "worker"
#  machine_secrets  = talos_machine_secrets.this.machine_secrets
#}
#
#
#resource "talos_machine_configuration_apply" "control_plane" {
#  for_each                    = local.control_plane_vms
#  depends_on                  = [proxmox_virtual_environment_vm.k8s_vm]
#  client_configuration        = talos_machine_secrets.this.client_configuration
#  machine_configuration_input = data.talos_machine_configuration.control_plane[each.key].machine_configuration
#  node                        = each.value.ip
#}
#
#resource "talos_machine_configuration_apply" "worker" {
#  for_each                    = local.worker_vms
#  depends_on                  = [proxmox_virtual_environment_vm.k8s_vm]
#  client_configuration        = talos_machine_secrets.this.client_configuration
#  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
#  node                        = each.value.ip
#}
#
#resource "talos_machine_bootstrap" "this" {
#  depends_on           = [talos_machine_configuration_apply.control_plane]
#  client_configuration = talos_machine_secrets.this.client_configuration
#  node                 = local.control_plane_node_ips[0]
#}
#
#data "talos_cluster_health" "this" {
#  depends_on = [
#    talos_machine_configuration_apply.control_plane,
#    talos_machine_configuration_apply.worker
#  ]
#
#  client_configuration = data.talos_client_configuration.this.client_configuration
#  control_plane_nodes  = local.control_plane_node_ips
#  worker_nodes         = local.worker_node_ips
#  endpoints            = local.control_plane_node_ips
#}
#
#data "talos_cluster_kubeconfig" "this" {
#  depends_on = [
#    talos_machine_bootstrap.this,
#    data.talos_cluster_health.this
#  ]
#
#  client_configuration = talos_machine_secrets.this.client_configuration
#  node                 = local.control_plane_node_ips[0]
#}
#
##output "kubeconfig" {
##  sensitive = true
##  value     = data.talos_cluster_kubeconfig.this.kubeconfig
##}
#resource "local_file" "talosconfig" {
#  filename = "${path.module}/talosconfig"
#  content  = data.talos_client_configuration.this.talos_config
#}
#
