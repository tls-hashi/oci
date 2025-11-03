# Vault provider configuration for HCP Vault
provider "vault" {
  # When using HCP Terraform dynamic credentials, do not set address/namespace here
  # They are automatically configured via environment variables:
  # - TFC_VAULT_ADDR
  # - TFC_VAULT_NAMESPACE
  # - TFC_VAULT_RUN_ROLE
  # - vault_backed_dynamic_credentials (workspace variable)
  
  # The token is automatically injected by HCP Terraform's dynamic credentials
  # Do NOT set 'token', 'address', or 'namespace' here
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
