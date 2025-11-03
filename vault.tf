# Vault provider configuration for HCP Vault
provider "vault" {
  # Address and namespace are set via environment variables in HCP Terraform:
  # - TFC_VAULT_ADDR
  # - TFC_VAULT_NAMESPACE
  # Authentication token is automatically injected by HCP Terraform via:
  # - TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS
  # - TFC_VAULT_RUN_ROLE
  
  address   = "https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
  namespace = "admin"
  
  # Do NOT set 'token' - automatically injected via dynamic credentials
}

# Fetch OCI credentials from Vault
# Using data source (not ephemeral) because values must persist in state
data "vault_kv_secret_v2" "oci" {
  mount = "oci"
  name  = "terraform"
}

# Local values for easy reference to OCI credentials
locals {
  oci_creds = data.vault_kv_secret_v2.oci.data

  # Extract OCI credentials from Vault
  tenancy_ocid     = local.oci_creds.tenancy_ocid
  user_ocid        = local.oci_creds.user_ocid
  fingerprint      = local.oci_creds.fingerprint
  private_key      = local.oci_creds.private_key
  compartment_ocid = local.oci_creds.compartment_ocid
  region           = local.oci_creds.region
}
