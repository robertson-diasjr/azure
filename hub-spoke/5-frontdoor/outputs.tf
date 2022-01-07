###################
# Output Session
###################

output "webapp-vm-ip" {
  value = azurerm_linux_virtual_machine.webapp-vm.private_ip_address
}