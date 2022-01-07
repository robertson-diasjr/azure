terraform {
  required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.9"
    }
  }
}

provider "azurerm" {
  features {}
}

###################
# Setup: Resource Group
###################
resource "azurerm_resource_group" "lab" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_resource_group" "onprem" {
  name     = "${var.prefix}-rg-onprem"
  location = var.location
}

###################
# Setup: Log Analytics
###################
resource "azurerm_log_analytics_workspace" "lab" {
  name                = "${var.prefix}-demo-workspace"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}