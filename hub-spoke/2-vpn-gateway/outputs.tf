###################
# Output Session
###################

output "onprem-vpn-pip" {
  description = "OnPrem VPN GW Public IP"
  value = azurerm_public_ip.onprem-vpn-gateway-pip.ip_address
}

output "hub-vpn-pip" {
  description = "HUB VPN GW Public IP"
  value = azurerm_public_ip.hub-vpn-gateway-pip.ip_address
}
