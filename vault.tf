# Vault provider configuration for HCP Vault
provider "vault" {
  # Address and namespace must be set explicitly
  address   = "https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
  namespace = "admin"
  
  # The token is automatically injected by HCP Terraform's dynamic credentials via:
  # - TFC_VAULT_RUN_ROLE (env var)
  # - vault_backed_dynamic_credentials = true (terraform var)
  # Do NOT set 'token' here
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
