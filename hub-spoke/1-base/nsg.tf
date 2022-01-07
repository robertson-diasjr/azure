###################
# Setup: NSG
###################

resource "azurerm_network_security_group" "bastion-nsg" {
  name                = "${var.prefix}-bastion-nsg"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowGatewayManager"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 202
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowBastionHostCommunication"
    priority                   = 203
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 201
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  security_rule {
    name                       = "AllowBastionCommunication"
    priority                   = 202
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "AllowGetSessionInformation"
    priority                   = 203
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion-nsg" {
  subnet_id                 = azurerm_subnet.AzureBastionSubnet.id
  network_security_group_id = azurerm_network_security_group.bastion-nsg.id
  depends_on                = [azurerm_subnet.AzureBastionSubnet]
}

#------------------------------------------------------------------------------

resource "azurerm_network_security_group" "spoke1-subnet-nsg" {
  name                = "${var.prefix}-spoke1-subnet-nsg"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
}

resource "azurerm_subnet_network_security_group_association" "spoke1-subnet-nsg" {
  subnet_id                 = azurerm_subnet.spoke1-subnet.id
  network_security_group_id = azurerm_network_security_group.spoke1-subnet-nsg.id
}

#------------------------------------------------------------------------------

resource "azurerm_network_security_group" "spoke2-subnet-nsg" {
  name                = "${var.prefix}-spoke2-subnet-nsg"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
}

resource "azurerm_subnet_network_security_group_association" "spoke2-subnet-nsg" {
  subnet_id                 = azurerm_subnet.spoke2-subnet.id
  network_security_group_id = azurerm_network_security_group.spoke2-subnet-nsg.id
}

#------------------------------------------------------------------------------

resource "azurerm_network_security_group" "onprem-subnet-nsg" {
  name                = "${var.prefix}-onprem-subnet-nsg"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = azurerm_resource_group.onprem.location
}

resource "azurerm_subnet_network_security_group_association" "onprem-subnet-nsg" {
  subnet_id                 = azurerm_subnet.onprem-subnet.id
  network_security_group_id = azurerm_network_security_group.onprem-subnet-nsg.id
}
