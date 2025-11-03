# No variables needed for basic HCP Terraform dynamic credentials with Vault
# Dynamic credentials are configured via workspace environment variables:
# - TFC_VAULT_PROVIDER_AUTH = true
# - TFC_VAULT_ADDR
# - TFC_VAULT_NAMESPACE
# - TFC_VAULT_RUN_ROLE

variable "instance_display_name" {
  description = "Display name for the compute instance"
  type        = string
  default     = "ubuntu-a1-instance"
}