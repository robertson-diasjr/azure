###################
# Setup: VNETs
###################
resource "azurerm_virtual_network" "vnet-hub" {
  name                = "${var.prefix}-vnet-hub"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network" "vnet-spoke1" {
  name                = "${var.prefix}-vnet-spoke1"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_virtual_network" "vnet-spoke2" {
  name                = "${var.prefix}-vnet-spoke2"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_virtual_network" "vnet-onprem" {
  name                = "${var.prefix}-vnet-onprem"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = azurerm_resource_group.onprem.location
  address_space       = ["10.3.0.0/16"]
}

###################
# Setup: Subnets
###################

resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.vnet-hub.name
  resource_group_name  = azurerm_resource_group.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet-hub.name
  resource_group_name  = azurerm_resource_group.lab.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "spoke1-subnet" {
  name                 = "spoke1-subnet"
  virtual_network_name = azurerm_virtual_network.vnet-spoke1.name
  resource_group_name  = azurerm_resource_group.lab.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "spoke2-subnet" {
  name                 = "spoke2-subnet"
  virtual_network_name = azurerm_virtual_network.vnet-spoke2.name
  resource_group_name  = azurerm_resource_group.lab.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_subnet" "hub-gw-subnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet-hub.name
  resource_group_name  = azurerm_resource_group.lab.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "onprem-gw-subnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet-onprem.name
  resource_group_name  = azurerm_resource_group.onprem.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_subnet" "onprem-subnet" {
  name                 = "onprem-subnet"
  virtual_network_name = azurerm_virtual_network.vnet-onprem.name
  resource_group_name  = azurerm_resource_group.onprem.name
  address_prefixes     = ["10.3.2.0/24"]
}

###################
# Setup: Peering
###################

resource "azurerm_virtual_network_peering" "spoke1-hub" {
  name                      = "spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.lab.name
  virtual_network_name      = azurerm_virtual_network.vnet-spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.vnet-spoke1, azurerm_virtual_network.vnet-hub]
}

resource "azurerm_virtual_network_peering" "hub-spoke1" {
  name                      = "hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.lab.name
  virtual_network_name      = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-spoke1.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network_peering.spoke1-hub]
}

#------------------------------------------------------------------------------

resource "azurerm_virtual_network_peering" "spoke2-hub" {
  name                      = "spoke2-to-hub"
  resource_group_name       = azurerm_resource_group.lab.name
  virtual_network_name      = azurerm_virtual_network.vnet-spoke2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.vnet-spoke2, azurerm_virtual_network.vnet-hub]
}

resource "azurerm_virtual_network_peering" "hub-spoke2" {
  name                      = "hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.lab.name
  virtual_network_name      = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-spoke2.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network_peering.spoke2-hub]
}

###################
# Setup: Route Table
###################

resource "azurerm_route_table" "routes-for-spoke1" {
  name                          = "routes-for-spoke1"
  resource_group_name           = azurerm_resource_group.lab.name
  location                      = azurerm_resource_group.lab.location
  disable_bgp_route_propagation = true
  depends_on                    = [azurerm_firewall.azfw]

  route {
    name                   = "to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }

  route {
    name                   = "to-spoke-2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }

  route {
    name                   = "to-onprem"
    address_prefix         = "10.3.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }
}

resource "azurerm_subnet_route_table_association" "spoke1-subnet-rt" {
  subnet_id      = azurerm_subnet.spoke1-subnet.id
  route_table_id = azurerm_route_table.routes-for-spoke1.id
  depends_on     = [azurerm_virtual_network_peering.hub-spoke1]
}

#------------------------------------------------------------------------------

resource "azurerm_route_table" "routes-for-spoke2" {
  name                          = "routes-for-spoke2"
  resource_group_name           = azurerm_resource_group.lab.name
  location                      = azurerm_resource_group.lab.location
  disable_bgp_route_propagation = true
  depends_on                    = [azurerm_firewall.azfw]

  route {
    name                   = "to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }

  route {
    name                   = "to-spoke-1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }

  route {
    name                   = "to-onprem"
    address_prefix         = "10.3.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }
}

resource "azurerm_subnet_route_table_association" "spoke-2-subnet-rt" {
  subnet_id      = azurerm_subnet.spoke2-subnet.id
  route_table_id = azurerm_route_table.routes-for-spoke2.id
  depends_on     = [azurerm_virtual_network_peering.hub-spoke2]
}

#------------------------------------------------------------------------------

resource "azurerm_route_table" "routes-for-vpngw" {
  name                          = "routes-for-vpngw"
  resource_group_name           = azurerm_resource_group.lab.name
  location                      = azurerm_resource_group.lab.location
  disable_bgp_route_propagation = true
  depends_on                    = [azurerm_firewall.azfw]

  route {
    name                   = "to-spoke-1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }

  route {
    name                   = "to-spoke-2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }
}

resource "azurerm_subnet_route_table_association" "vpngw-subnet-rt" {
  subnet_id      = azurerm_subnet.hub-gw-subnet.id
  route_table_id = azurerm_route_table.routes-for-vpngw.id
  depends_on     = [azurerm_virtual_network_peering.hub-spoke1, azurerm_virtual_network_peering.hub-spoke2]
}

#------------------------------------------------------------------------------

###################
# Setup: IP Group
###################

resource "azurerm_ip_group" "ipgroup-spoke" {
  name                = "${var.prefix}-spokes"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  cidrs               = ["10.1.0.0/16", "10.2.0.0/16"]
}

resource "azurerm_ip_group" "ipgroup-webapp" {
  name                = "${var.prefix}-webapp"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  cidrs               = ["192.168.0.0/28"]
}

resource "azurerm_ip_group" "ipgroup-onprem" {
  name                = "${var.prefix}-onprem"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  cidrs               = ["10.3.0.0/16"]
}
