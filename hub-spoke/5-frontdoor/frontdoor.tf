###################
# Setup: Data Sources
###################

data "azurerm_resource_group" "lab" {
  name = "${var.prefix}-rg"
}

data "azurerm_resource_group" "onprem" {
  name = "${var.prefix}-rg-onprem"
}

data "azurerm_public_ip" "azfw-pip" {
  name = "${var.prefix}-azfw-pip"
  resource_group_name = data.azurerm_resource_group.lab.name
}

data "azurerm_firewall_policy" "azfw-policy" {
  name = "${var.prefix}-azfw-policy"
  resource_group_name = data.azurerm_resource_group.lab.name
}

data "azurerm_log_analytics_workspace" "lab" {
  name = "${var.prefix}-demo-workspace"
  resource_group_name = data.azurerm_resource_group.lab.name
}

data "azurerm_virtual_network" "vnet-hub" {
  name                  = "${var.prefix}-vnet-hub"
  resource_group_name   = data.azurerm_resource_group.lab.name
}

###################
# Setup: FrontDoor
###################

resource "azurerm_frontdoor" "lab" {
  name                            = "${var.prefix}-FrontDoor"
  resource_group_name             = data.azurerm_resource_group.lab.name
  enforce_backend_pools_certificate_name_check = false
  
  routing_rule {
    name                          = "routing-rule"
    accepted_protocols            = ["Http", "Https"]
    patterns_to_match             = ["/*"]
    frontend_endpoints            = ["FrontendEndpoint"]
    forwarding_configuration {
      forwarding_protocol         = "MatchRequest"
      backend_pool_name           = "${var.prefix}-backend-webapp"
    }
  }

  backend_pool_load_balancing {
    name = "LBSettings"
  }

  backend_pool_health_probe {
    name          = "HealthProbeSettings"
    enabled       = true
    probe_method  = "HEAD"
  }

  backend_pool {
    name = "${var.prefix}-backend-webapp"
    backend {
      host_header = "${var.prefix}-FrontDoor.azurefd.net"
      address      = data.azurerm_public_ip.azfw-pip.ip_address
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "LBSettings"
    health_probe_name   = "HealthProbeSettings"
  }

  frontend_endpoint {
    name                          = "FrontendEndpoint"
    host_name                     = "${var.prefix}-FrontDoor.azurefd.net"
    session_affinity_enabled      = false
    session_affinity_ttl_seconds  = 0
    web_application_firewall_policy_link_id = azurerm_frontdoor_firewall_policy.lab.id
  }
}

#--------------------------------------------------------------------------

###################
# Setup: FrontDoor WAF
###################

resource "azurerm_frontdoor_firewall_policy" "lab" {
  name                              = "FrontDoorWAFPolicy"
  resource_group_name               = data.azurerm_resource_group.lab.name
  enabled                           = true
  mode                              = "Prevention"

  custom_rule {
    name                           = "Rule1"
    enabled                        = true
    priority                       = 1
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 10
    type                           = "MatchRule"
    action                         = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }
  }

  managed_rule {
    type = "DefaultRuleSet"
    version = "1.0"
  }
}

#--------------------------------------------------------------------------

###################
# Setup: IP Group
###################

resource "azurerm_ip_group" "ipgroup-afd" {
  name                = "${var.prefix}-frontdoor"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name
  cidrs               = ["13.73.248.16/29", "20.21.37.40/29", "20.36.120.104/29", "20.37.64.104/29", "20.37.156.120/29", "20.37.195.0/29", "20.37.224.104/29", "20.38.84.72/29", "20.38.136.104/29", "20.39.11.8/29", "20.41.4.88/29", "20.41.64.120/29", "20.41.192.104/29", "20.42.4.120/29", "20.42.129.152/29", "20.42.224.104/29", "20.43.41.136/29", "20.43.65.128/29", "20.43.130.80/29", "20.45.112.104/29", "20.45.192.104/29", "20.59.103.64/29", "20.72.18.248/29", "20.88.157.176/29", "20.90.132.152/29", "20.115.247.64/29", "20.118.195.128/29", "20.119.155.128/29", "20.150.160.96/29", "20.189.106.112/29", "20.192.161.104/29", "20.192.225.48/29", "40.67.48.104/29", "40.74.30.72/29", "40.80.56.104/29", "40.80.168.104/29", "40.80.184.120/29", "40.82.248.248/29", "40.89.16.104/29", "51.12.41.8/29", "51.12.193.8/29", "51.104.25.128/29", "51.105.80.104/29", "51.105.88.104/29", "51.107.48.104/29", "51.107.144.104/29", "51.120.40.104/29", "51.120.224.104/29", "51.137.160.112/29", "51.143.192.104/29", "52.136.48.104/29", "52.140.104.104/29", "52.150.136.120/29", "52.159.71.160/29", "52.228.80.120/29", "102.133.56.88/29", "102.133.216.88/29", "147.243.0.0/16", "191.233.9.120/29", "191.235.225.128/29"]
}

#--------------------------------------------------------------------------

###################
# Setup: FIREWALL POLICY NAT
###################

resource "azurerm_firewall_policy_rule_collection_group" "azfw-collection-nat" {
  name                    = "${var.prefix}-azfw-collection-nat"
  firewall_policy_id      = data.azurerm_firewall_policy.azfw-policy.id
  priority                = 400
  depends_on              = [azurerm_network_interface.webapp-vm-nic]
  
  nat_rule_collection {
    name                    = "nat-rules"
    priority                = 200
    action                  = "Dnat"
    rule {
      name                  = "webapp-http"
      protocols             = ["TCP"]
      source_addresses      = azurerm_ip_group.ipgroup-afd.cidrs
      destination_address   = data.azurerm_public_ip.azfw-pip.ip_address
      destination_ports     = ["80"]
      translated_address    = azurerm_network_interface.webapp-vm-nic.private_ip_address
      translated_port       = "80"
    }
      rule {
      name                  = "webapp-https"
      protocols             = ["TCP"]
      source_addresses      = azurerm_ip_group.ipgroup-afd.cidrs
      destination_address   = data.azurerm_public_ip.azfw-pip.ip_address
      destination_ports     = ["443"]
      translated_address    = azurerm_network_interface.webapp-vm-nic.private_ip_address
      translated_port       = "443"
    }
  }
}

###################
# Setup: Diagnostic Settings
###################

resource "azurerm_monitor_diagnostic_setting" "frontdoor-diag-set" {
  name                        = "FrontDoor-Logs-to-LA"
  target_resource_id          = azurerm_frontdoor.lab.id
  log_analytics_workspace_id  = data.azurerm_log_analytics_workspace.lab.id
  
  log {
    category = "FrontdoorWebApplicationFirewallLog"
    enabled  = "true"
  }
  log {
    category = "FrontdoorAccessLog"
    enabled  = "true"
  }
}