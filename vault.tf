# Vault provider configuration for HCP Vault
# Uses HCP Terraform Dynamic Credentials for authentication

provider "vault" {
  # Address and namespace must be set explicitly for the provider
  # Authentication token is provided automatically by HCP Terraform Dynamic Credentials
  address   = "https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
  namespace = "admin"
  
  # Do NOT set 'token' - it's automatically injected by HCP Terraform
  # when TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS = true
  
  # Required HCP Terraform workspace environment variables:
  # - TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS = true
  # - TFC_VAULT_ADDR = https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200
  # - TFC_VAULT_NAMESPACE = admin
  # - TFC_VAULT_RUN_ROLE = tfc-oci
}

# Fetch OCI credentials from Vault KV v2 secrets engine
data "vault_kv_secret_v2" "oci" {
  mount = "oci"       # KV v2 mount path
  name  = "terraform" # Secret name under the mount
}

# Local values for easy reference throughout the configuration
locals {
  oci_creds = data.vault_kv_secret_v2.oci.data
  
  # Extract OCI credentials
  tenancy_ocid     = local.oci_creds.tenancy_ocid
  user_ocid        = local.oci_creds.user_ocid
  fingerprint      = local.oci_creds.fingerprint
  private_key      = local.oci_creds.private_key
  compartment_ocid = local.oci_creds.compartment_ocid
  region           = local.oci_creds.region
}
