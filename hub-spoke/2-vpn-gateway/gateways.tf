###################
# Setup: VPN Gateways
###################

data "azurerm_resource_group" "lab" {
  name = "${var.prefix}-rg"
}

data "azurerm_resource_group" "onprem" {
  name = "${var.prefix}-rg-onprem"
}

data "azurerm_virtual_network" "vnet-hub" {
  name                  = "${var.prefix}-vnet-hub"
  resource_group_name   = data.azurerm_resource_group.lab.name
} 

data "azurerm_virtual_network" "vnet-onprem" {
  name                  = "${var.prefix}-vnet-onprem"
  resource_group_name   = data.azurerm_resource_group.onprem.name
}

data "azurerm_subnet" "hub-gw-subnet" {
  name                  = "GatewaySubnet"
  virtual_network_name  = data.azurerm_virtual_network.vnet-hub.name
  resource_group_name   = data.azurerm_resource_group.lab.name
}

data "azurerm_subnet" "onprem-gw-subnet" {
  name                  = "GatewaySubnet"
  virtual_network_name  = data.azurerm_virtual_network.vnet-onprem.name
  resource_group_name   = data.azurerm_resource_group.onprem.name
}

data "azurerm_log_analytics_workspace" "lab" {
  name = "${var.prefix}-demo-workspace"
  resource_group_name = data.azurerm_resource_group.lab.name
}

############################
# Virtual Network Gateway - On Premises
############################

resource "azurerm_public_ip" "onprem-vpn-gateway-pip" {
    name                = "${var.prefix}-onprem-vpn-gateway-pip"
    location            = data.azurerm_resource_group.onprem.location
    resource_group_name = data.azurerm_resource_group.onprem.name
    allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "onprem-vpn-gateway" {
    name                = "${var.prefix}-onprem-vpn-gateway"
    location            = data.azurerm_resource_group.onprem.location
    resource_group_name = data.azurerm_resource_group.onprem.name
    type                = "Vpn"
    vpn_type            = "RouteBased"
    sku                 = "VpnGw1"
    active_active       = false
    enable_bgp          = false
    depends_on          = [azurerm_public_ip.onprem-vpn-gateway-pip]
    
    ip_configuration {
        name                          = "onprem-vpn-gateway-ip"
        public_ip_address_id          = azurerm_public_ip.onprem-vpn-gateway-pip.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = data.azurerm_subnet.onprem-gw-subnet.id
    }
    
    timeouts {
        create = "1h"
        delete = "1h"
        update = "1h"
        read   = "1h"
    }
}

############################
# Virtual Network Gateway - HUB
############################

resource "azurerm_public_ip" "hub-vpn-gateway-pip" {
    name                = "${var.prefix}-hub-vpn-gateway-pip"
    location            = data.azurerm_resource_group.lab.location
    resource_group_name = data.azurerm_resource_group.lab.name
    allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "hub-vpn-gateway" {
    name                = "${var.prefix}-hub-vpn-gateway"
    location            = data.azurerm_resource_group.lab.location
    resource_group_name = data.azurerm_resource_group.lab.name
    type                = "Vpn"
    vpn_type            = "RouteBased"
    sku                 = "VpnGw1"
    active_active       = false
    enable_bgp          = false
    depends_on          = [azurerm_public_ip.hub-vpn-gateway-pip]

    ip_configuration {
        name                          = "hub-vpn-gateway-ip"
        public_ip_address_id          = azurerm_public_ip.hub-vpn-gateway-pip.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = data.azurerm_subnet.hub-gw-subnet.id
    }

    timeouts {
        create = "1h"
        delete = "1h"
        update = "1h"
        read   = "1h"
    }
}

#------------------------------------------------------------------------------

###################
# Setup: Diagnostic Settings
###################

resource "azurerm_monitor_diagnostic_setting" "hub-vpn-gateway-pip-diag-set" {
  name                        = "VPN-Logs-to-LA"
  target_resource_id          = azurerm_public_ip.hub-vpn-gateway-pip.id
  log_analytics_workspace_id  = data.azurerm_log_analytics_workspace.lab.id
  
  log {
    category = "DDoSProtectionNotifications"
    enabled  = "true"
  }
  log {
    category = "DDoSMitigationFlowLogs"
    enabled  = "true"
  }
  log {
    category = "DDoSMitigationReports"
    enabled  = "true"
  }
}

resource "azurerm_monitor_diagnostic_setting" "onprem-vpn-gateway-pip-diag-set" {
  name                        = "VPN-Logs-to-LA"
  target_resource_id          = azurerm_public_ip.onprem-vpn-gateway-pip.id
  log_analytics_workspace_id  = data.azurerm_log_analytics_workspace.lab.id
  
  log {
    category = "DDoSProtectionNotifications"
    enabled  = "true"
  }
  log {
    category = "DDoSMitigationFlowLogs"
    enabled  = "true"
  }
  log {
    category = "DDoSMitigationReports"
    enabled  = "true"
  }
}