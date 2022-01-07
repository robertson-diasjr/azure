###################
# Setup: AZURE FIREWALL
###################

resource "azurerm_public_ip" "azfw-pip" {
  name                = "${var.prefix}-azfw-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "azfw-policy" {
  name                     = "${var.prefix}-azfw-policy"
  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  sku                      = "Premium"
  threat_intelligence_mode = "Alert"
}

resource "azurerm_firewall" "azfw" {
  name                 = "${var.prefix}-azure-firewall"
  resource_group_name  = azurerm_resource_group.lab.name
  location             = azurerm_resource_group.lab.location
  sku_tier             = "Premium"
  firewall_policy_id   = azurerm_firewall_policy.azfw-policy.id
  depends_on           = [azurerm_firewall_policy.azfw-policy]

  ip_configuration {
    name                 = "${var.prefix}-azfw-ip-configuration"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.azfw-pip.id
  }
    timeouts {
    create = "1h"
    delete = "1h"
    update = "1h"
    read   = "1h"
  }
}

###################
# Setup: FIREWALL POLICY
###################

########################
# Multiple Collections
########################

resource "azurerm_firewall_policy_rule_collection_group" "azfw-collection-network" {
  name                    = "${var.prefix}-azfw-collection-network"
  firewall_policy_id      = azurerm_firewall_policy.azfw-policy.id
  priority                = 600
  depends_on              = [azurerm_firewall.azfw]
  
  network_rule_collection {
    name                    = "network-filtering"
    priority                = 300
    action                  = "Allow"
    rule {
      name                  = "spoke-spoke"
      protocols             = ["Any"]
      source_addresses      = azurerm_ip_group.ipgroup-spoke.cidrs
      destination_addresses = azurerm_ip_group.ipgroup-spoke.cidrs
      destination_ports     = ["*"]
    }
    rule {
      name                  = "spoke-to-onprem"
      protocols             = ["Any"]
      source_addresses      = azurerm_ip_group.ipgroup-spoke.cidrs
      destination_addresses = azurerm_ip_group.ipgroup-onprem.cidrs
      destination_ports     = ["*"]
    }
    rule {
      name                  = "onprem-to-spoke"
      protocols             = ["Any"]
      source_addresses      = azurerm_ip_group.ipgroup-onprem.cidrs
      destination_addresses = azurerm_ip_group.ipgroup-spoke.cidrs
      destination_ports     = ["*"]
    }
      rule {
      name                  = "spoke-to-internet"
      protocols             = ["TCP"]
      source_addresses      = azurerm_ip_group.ipgroup-spoke.cidrs
      destination_addresses = ["Any"]
      destination_ports     = ["80", "443"]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "azfw-collection-app" {
  name                    = "${var.prefix}-azfw-collection-app"
  firewall_policy_id      = azurerm_firewall_policy.azfw-policy.id
  priority                = 800
  depends_on              = [azurerm_firewall.azfw]

  application_rule_collection {
    name                = "web-filtering"
    priority            = 400
    action              = "Allow"
    rule {
        name            = "Web Access"
        protocols {
          type          = "Http"
          port          = 80
      }
      protocols {
        type            = "Https"
        port            = 443
      }
      source_addresses  = azurerm_ip_group.ipgroup-spoke.cidrs
      destination_fqdns = ["*"]
    }
  }
}

#------------------------------------------------------------------------------

###################
# Setup: Diagnostic Settings
###################

resource "azurerm_monitor_diagnostic_setting" "azfw-diag-set" {
  name                        = "Firewall-Logs-to-LA"
  target_resource_id          = azurerm_firewall.azfw.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.lab.id
  depends_on                  = [azurerm_log_analytics_workspace.lab]

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = "true"
  }
  log {
    category = "AzureFirewallNetworkRule"
    enabled  = "true"
  }
  log {
    category = "AzureFirewallDnsProxy"
    enabled  = "true"
  }
}

#------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "azfw-pip-diag-set" {
  name                        = "Firewall-PIP-Logs-to-LA"
  target_resource_id          = azurerm_public_ip.azfw-pip.id
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