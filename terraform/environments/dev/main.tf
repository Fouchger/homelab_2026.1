provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

# =============================================================================
# Starter example (commented)
# =============================================================================
# The bpg/proxmox provider supports downloading images to a datastore and creating
# VMs/LXC resources. We keep this baseline minimal, and recommend adding your
# resources via modules under terraform/modules.
#
# resource "proxmox_virtual_environment_download_file" "ubuntu_2404_cloudimg" {
#   content_type = "import"
#   datastore_id = "local"
#   node_name    = var.proxmox_node_name
#   url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
#   file_name    = "noble-server-cloudimg-amd64.qcow2"
# }
