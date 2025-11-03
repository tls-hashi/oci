provider "vault" {
  address   = "https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
  namespace = "admin"
  # Token comes from VAULT_TOKEN environment variable
}

data "vault_kv_secret_v2" "oci" {
  mount = "oci"
  name  = "terraform"
}

locals {
  oci_creds = data.vault_kv_secret_v2.oci.data
  
  tenancy_ocid     = local.oci_creds["tenancy_ocid"]
  user_ocid        = local.oci_creds["user_ocid"]
  fingerprint      = local.oci_creds["fingerprint"]
  private_key      = local.oci_creds["private_key"]
  compartment_ocid = local.oci_creds["compartment_ocid"]
  region           = local.oci_creds["region"]
}

provider "oci" {
  tenancy_ocid = local.tenancy_ocid
  user_ocid    = local.user_ocid
  fingerprint  = local.fingerprint
  private_key  = local.private_key
  region       = local.region
}