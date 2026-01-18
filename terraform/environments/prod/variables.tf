variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://pve.example.com:8006/api2/json"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow insecure TLS (not recommended)"
  type        = bool
  default     = false
}

variable "proxmox_node_name" {
  description = "Default node name"
  type        = string
}
