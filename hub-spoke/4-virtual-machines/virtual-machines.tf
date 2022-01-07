###################
# Setup: Data Sources
###################

data "azurerm_resource_group" "lab" {
  name = "${var.prefix}-rg"
}

data "azurerm_resource_group" "onprem" {
  name = "${var.prefix}-rg-onprem"
}

data "azurerm_virtual_network" "vnet-spoke1" {
  name                  = "${var.prefix}-vnet-spoke1"
  resource_group_name   = data.azurerm_resource_group.lab.name
}

data "azurerm_virtual_network" "vnet-spoke2" {
  name                  = "${var.prefix}-vnet-spoke2"
  resource_group_name   = data.azurerm_resource_group.lab.name
} 

data "azurerm_virtual_network" "vnet-onprem" {
  name                  = "${var.prefix}-vnet-onprem"
  resource_group_name   = data.azurerm_resource_group.onprem.name
}

data "azurerm_subnet" "spoke1-subnet" {
  name                  = "spoke1-subnet"
  virtual_network_name  = data.azurerm_virtual_network.vnet-spoke1.name
  resource_group_name   = data.azurerm_resource_group.lab.name
}

data "azurerm_subnet" "spoke2-subnet" {
  name                  = "spoke2-subnet"
  virtual_network_name  = data.azurerm_virtual_network.vnet-spoke2.name
  resource_group_name   = data.azurerm_resource_group.lab.name
}

data "azurerm_subnet" "onprem-subnet" {
  name                  = "onprem-subnet"
  virtual_network_name  = data.azurerm_virtual_network.vnet-onprem.name
  resource_group_name   = data.azurerm_resource_group.onprem.name
}

###################
# Setup: VM Spoke1
###################

resource "azurerm_network_interface" "spoke1-vm-nic" {
  name                = "${var.prefix}-spoke1-vm-nic"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = data.azurerm_resource_group.lab.location

  ip_configuration {
    name                          = "${var.prefix}-spoke1-vm-ip-configuration"
    subnet_id                     = data.azurerm_subnet.spoke1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "spoke1-vm" {
  name                            = "${var.prefix}-spoke1-vm-1"
  resource_group_name             = data.azurerm_resource_group.lab.name
  location                        = data.azurerm_resource_group.lab.location
  size                            = "${var.vm-size}"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = filebase64("user-data.sh")
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.spoke1-vm-nic.id, ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-spoke1-vm-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

#------------------------------------------------------------------------------

###################
# Setup: VM Spoke2
###################

resource "azurerm_network_interface" "spoke2-vm-nic" {
  name                = "${var.prefix}-spoke2-vm-nic"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = data.azurerm_resource_group.lab.location

  ip_configuration {
    name                          = "${var.prefix}-spoke2-vm-ip-configuration"
    subnet_id                     = data.azurerm_subnet.spoke2-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "spoke2-vm" {
  name                            = "${var.prefix}-spoke2-vm-1"
  resource_group_name             = data.azurerm_resource_group.lab.name
  location                        = data.azurerm_resource_group.lab.location
  size                            = "${var.vm-size}"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = filebase64("user-data.sh")
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.spoke2-vm-nic.id, ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-spoke2-vm-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

#------------------------------------------------------------------------------

###################
# Setup: VM Onpremises
###################

resource "azurerm_network_interface" "onprem-subnet-vm-nic" {
  name                = "${var.prefix}-onprem-subnet-vm-nic"
  resource_group_name = data.azurerm_resource_group.onprem.name
  location            = data.azurerm_resource_group.onprem.location

  ip_configuration {
    name                          = "${var.prefix}-onprem-vm-ip-configuration"
    subnet_id                     = data.azurerm_subnet.onprem-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "onprem-subnet-vm" {
  name                            = "${var.prefix}-onprem-vm-1"
  resource_group_name             = data.azurerm_resource_group.onprem.name
  location                        = data.azurerm_resource_group.onprem.location
  size                            = "${var.vm-size}"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = filebase64("user-data.sh")
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.onprem-subnet-vm-nic.id, ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-onprem-subnet-vm-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}
