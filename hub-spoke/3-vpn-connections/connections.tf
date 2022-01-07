###################
# Setup: VPN Connections
###################

data "azurerm_resource_group" "lab" {
  name = "${var.prefix}-rg"
}

data "azurerm_resource_group" "onprem" {
  name = "${var.prefix}-rg-onprem"
}

data "azurerm_public_ip" "onprem-vpn-gateway-pip" {
  name                = "${var.prefix}-onprem-vpn-gateway-pip"
  resource_group_name = data.azurerm_resource_group.onprem.name
}

data "azurerm_public_ip" "hub-vpn-gateway-pip" {
  name                = "${var.prefix}-hub-vpn-gateway-pip"
  resource_group_name = data.azurerm_resource_group.lab.name
}

data "azurerm_ip_group" "ipgroup-spoke" {
  name                = "${var.prefix}-spokes"
  resource_group_name = data.azurerm_resource_group.lab.name
}

data "azurerm_ip_group" "ipgroup-onprem" {
  name                = "${var.prefix}-onprem"
  resource_group_name = data.azurerm_resource_group.lab.name
}

data "azurerm_virtual_network_gateway" "onprem-vpn-gateway" {
  name		      = "${var.prefix}-onprem-vpn-gateway"
  resource_group_name = data.azurerm_resource_group.onprem.name
}

data "azurerm_virtual_network_gateway" "hub-vpn-gateway" {
  name                = "${var.prefix}-hub-vpn-gateway"
  resource_group_name = data.azurerm_resource_group.lab.name
}

#----------------------------------------------------------------------------
resource "azurerm_local_network_gateway" "onprem-local-net-gw" {
    name                = "${var.prefix}-onprem-local-net-gw"
    location            = data.azurerm_resource_group.onprem.location
    resource_group_name = data.azurerm_resource_group.onprem.name
    gateway_address     = data.azurerm_public_ip.onprem-vpn-gateway-pip.ip_address
    address_space       = data.azurerm_ip_group.ipgroup-onprem.cidrs
}

resource "azurerm_local_network_gateway" "hub-local-net-gw" {
    name                = "${var.prefix}-hub-local-net-gw"
    location            = data.azurerm_resource_group.lab.location
    resource_group_name = data.azurerm_resource_group.lab.name
    gateway_address     = data.azurerm_public_ip.hub-vpn-gateway-pip.ip_address
    address_space       = data.azurerm_ip_group.ipgroup-spoke.cidrs
}
#----------------------------------------------------------------------------
resource "azurerm_virtual_network_gateway_connection" "onprem-to-hub" {
    name                            = "onprem-to-hub"
    location                        = data.azurerm_resource_group.onprem.location
    resource_group_name             = data.azurerm_resource_group.onprem.name
    type                            = "IPsec"
    virtual_network_gateway_id      = data.azurerm_virtual_network_gateway.onprem-vpn-gateway.id
    local_network_gateway_id        = azurerm_local_network_gateway.hub-local-net-gw.id
    shared_key                      = "strong@secrets"
}

resource "azurerm_virtual_network_gateway_connection" "hub-to-onprem" {
    name                            = "hub-to-onprem"
    location                        = data.azurerm_resource_group.lab.location
    resource_group_name             = data.azurerm_resource_group.lab.name
    type                            = "IPsec"  
    virtual_network_gateway_id      = data.azurerm_virtual_network_gateway.hub-vpn-gateway.id
    local_network_gateway_id        = azurerm_local_network_gateway.onprem-local-net-gw.id
    shared_key                      = "strong@secrets"
}


