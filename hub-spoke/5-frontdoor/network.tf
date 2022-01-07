###################
# Setup: Network
###################

resource "azurerm_virtual_network" "vnet-webapp" {
  name                = "${var.prefix}-vnet-webapp"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = data.azurerm_resource_group.lab.location
  address_space       = ["192.168.0.0/24"]
}

resource "azurerm_subnet" "webapp-subnet" {
  name                 = "webapp-subnet"
  virtual_network_name = azurerm_virtual_network.vnet-webapp.name
  resource_group_name  = data.azurerm_resource_group.lab.name
  address_prefixes     = ["192.168.0.0/28"]
}

resource "azurerm_virtual_network_peering" "webapp-hub" {
  name                      = "webapp-to-hub"
  resource_group_name       = data.azurerm_resource_group.lab.name
  virtual_network_name      = azurerm_virtual_network.vnet-webapp.name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet-hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub-webapp" {
  name                      = "hub-to-webapp"
  resource_group_name       = data.azurerm_resource_group.lab.name
  virtual_network_name      = data.azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-webapp.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false  
}

resource "azurerm_network_security_group" "webapp-subnet-nsg" {
  name                = "${var.prefix}-webapp-subnet-nsg"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = data.azurerm_resource_group.lab.location
}

resource "azurerm_subnet_network_security_group_association" "webapp-subnet-nsg" {
  subnet_id                 = azurerm_subnet.webapp-subnet.id
  network_security_group_id = azurerm_network_security_group.webapp-subnet-nsg.id
}