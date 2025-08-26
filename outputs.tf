output "vm_primary_ip" {
  value = module.testvm.virtual_machine_azurerm.private_ip_address
}

output "subnets_output" {
  value = module.vnet.subnets
}