variable "prefix" {
  default     = "lab"
  description = "Prefix of the resource."
}

variable "vm-size" {
  default     = "Standard_DS1_v2"
  description = "Virtual Machines Model"
}

variable "username" {
  default     = "azure-admin"
  description = "User ID of the Linux VMs."
}

variable "password" {
  default     = "strong@password"
  description = "Password of the Linux VMs."
}
