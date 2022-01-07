###################
# Output Session
###################

output "firewall_private_ip" {
  description = "Azure Firewall Private IP"
  value       = azurerm_firewall.azfw.ip_configuration[0].private_ip_address
}

output "firewall_pip" {
  description = "Azure Firewall Public IP"
  value       = azurerm_public_ip.azfw-pip.ip_address
}
