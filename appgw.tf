

#----------Testing Use Case  -------------
# Application Gateway + WAF Enable routing traffic from your application.
# Assume that your Application runing the scale set contains two virtual machine instances.
# The scale set is added to the default backend pool need to updated with IP or FQDN of the application gateway.
# The example input from https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-manage-web-traffic-cli

#----------All Required Provider Section-----------

# This ensures we have unique CAF compliant names for our resources.
module "agw_naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  suffix = ["agw"]
}

# This allows us to randomize the region for the resource group.
# module "regions" {
#   source  = "Azure/regions/azurerm"
#   version = ">= 0.3.0"
# }

# This allows us to randomize the region for the resource group.
# resource "random_integer" "region_index" {
#   max = length(module.regions.regions) - 1
#   min = 0
# }

resource "azurerm_web_application_firewall_policy" "example" {
  provider            = azurerm.spoke
  name                = "example-wafpolicy"
  location            = local.deployment_region
  resource_group_name = azurerm_resource_group.this_rg.name
  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }
  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

module "application_gateway" {
  providers = {
    azurerm = azurerm.spoke
  }

  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.4.3"

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    appGatewayBackendPool = {
      name         = "appGatewayBackendPool"
      ip_addresses = [module.testvm.virtual_machine_azurerm.private_ip_address]
    }
  }
  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {

    appGatewayBackendHttpSettings = {
      name            = "appGatewayBackendHttpSettings"
      port            = 80
      protocol        = "Http"
      path            = "/"
      request_timeout = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300
      }
    }
    # Add more http settings as needed
  }
  # frontend port configuration block for the application gateway
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = {
    frontend-port-80 = {
      name = "frontend-port-80"
      port = 80
    }
  }
  gateway_ip_configuration = {
    subnet_id = module.vnet.subnets.appgw_subnet_1.resource_id
  }
  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {
    appGatewayHttpListener = {
      name               = "appGatewayHttpListener"
      host_name          = null
      frontend_port_name = "frontend-port-80"
    }
    # # Add more http listeners as needed
  }
  location = local.deployment_region
  # provide Application gateway name
  name = module.agw_naming.application_gateway.name_unique
  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    routing-rule-1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "appGatewayHttpListener"
      backend_address_pool_name  = "appGatewayBackendPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 100
    }
    # Add more rules as needed
  }
  resource_group_name = azurerm_resource_group.this_rg.name
  # WAF : Use Application Gateway with Web Application Firewall (WAF) in an application virtual network to safeguard inbound HTTP/S internet traffic. WAF offers centralized defense against potential exploits through OWASP core rule sets-based rules.
  # Ensure that you have a WAF policy created before enabling WAF on the Application Gateway
  # The use of an external WAF policy is recommended rather than using the classic WAF via the waf_configuration block.
  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.example.id
  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }
  # WAF : Monitor and Log the configurations and traffic
  diagnostic_settings = {
    example_setting = {
      name                           = "${module.agw_naming.application_gateway.name_unique}-diagnostic-setting"
      workspace_resource_id          = "/subscriptions/1543411c-a55d-46d6-93bf-2e585fd51376/resourceGroups/rgbdo7-management-southeastasia/providers/Microsoft.OperationalInsights/workspaces/bdo7law-management-southeastasia"
      log_analytics_destination_type = "Dedicated" # Or "AzureDiagnostics"
      # log_categories                 = ["Application Gateway Access Log", "Application Gateway Performance Log", "Application Gateway Firewall Log"]
      log_groups        = ["allLogs"]
      metric_categories = ["AllMetrics"]
    }
  }
  enable_telemetry = var.enable_telemetry
  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "WAF_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "WAF_v2"
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 1 # Set the initial capacity to 0 for autoscaling
  }
  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }
  # Optional Input
  # Zone redundancy for the application gateway ["1", "2", "3"]
  zones = ["2"]
}


