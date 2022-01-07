###################
# Setup: VM webapp
###################

resource "azurerm_network_interface" "webapp-vm-nic" {
  name                = "${var.prefix}-webapp-vm-nic"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = data.azurerm_resource_group.lab.location

  ip_configuration {
    name                          = "${var.prefix}-webapp-vm-ip-configuration"
    subnet_id                     = azurerm_subnet.webapp-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "webapp-vm" {
  name                            = "${var.prefix}-webapp-vm-1"
  resource_group_name             = data.azurerm_resource_group.lab.name
  location                        = data.azurerm_resource_group.lab.location
  size                            = "${var.vm-size}"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = filebase64("user-data.sh")
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.webapp-vm-nic.id, ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-webapp-vm-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}