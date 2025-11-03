# Vault Policy for HCP Terraform OCI Workspace
# This policy grants read access to OCI credentials stored in Vault KV v2

# Read access to OCI credentials at oci/data/terraform
path "oci/data/terraform" {
  capabilities = ["read"]
}

# List access to the mount (helpful for debugging)
path "oci/metadata/terraform" {
  capabilities = ["read"]
}

# Allow listing the OCI mount
path "oci/metadata" {
  capabilities = ["list"]
}
