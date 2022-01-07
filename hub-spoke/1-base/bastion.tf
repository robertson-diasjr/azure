###################
# Setup: BASTION
###################

resource "azurerm_public_ip" "bastion-pip" {
  name                = "${var.prefix}-bastion-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.prefix}-bastion"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                 = "${var.prefix}-bastion-ip-configuration"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
  
  timeouts {
    create = "1h"
    delete = "1h"
    update = "1h"
    read   = "1h"
  }
}

###################
# Setup: Diagnostic Settings
###################

resource "azurerm_monitor_diagnostic_setting" "bastion-pip-diag-set" {
  name                        = "Bastion-Logs-to-LA"
  target_resource_id          = azurerm_public_ip.bastion-pip.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.lab.id
  depends_on                  = [azurerm_log_analytics_workspace.lab]

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