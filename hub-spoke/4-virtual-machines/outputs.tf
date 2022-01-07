###################
# Output Session
###################

output "onprem-vm-ip" {
  value = azurerm_linux_virtual_machine.onprem-subnet-vm.private_ip_address
}

output "spoke1-vm-ip" {
  value = azurerm_linux_virtual_machine.spoke1-vm.private_ip_address
}

output "spoke2-vm-ip" {
  value = azurerm_linux_virtual_machine.spoke2-vm.private_ip_address
}

