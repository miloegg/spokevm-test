module "avm-res-network-routetable" {
  providers = {
    azurerm = azurerm.spoke
  }
  source              = "Azure/avm-res-network-routetable/azurerm"
  version             = "0.4.1"
  location            = local.deployment_region
  name                = "sendtohubfw_rt"
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.this_rg.name
  routes = {
    hubfw = {
      name                   = "hubfw"
      address_prefix         = "172.16.0.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.1.0.1"
    }
  }
  subnet_resource_ids = {
    subnet1 = module.vnet.subnets.vm_subnet_1.resource_id
  }
}