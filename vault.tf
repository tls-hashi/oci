# Vault provider configuration for HCP Terraform dynamic credentials
provider "vault" {
  # Leave EMPTY for HCP Terraform dynamic credentials!
  # HCP Terraform automatically injects via environment variables:
  # - VAULT_ADDR (from TFC_VAULT_ADDR)
  # - VAULT_NAMESPACE (from TFC_VAULT_NAMESPACE)
  # - VAULT_TOKEN (generated via TFC_VAULT_RUN_ROLE)
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
