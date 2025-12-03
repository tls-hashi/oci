# Vault Policy for HCP Terraform OCI Workspace
# This policy grants read/write access to credentials and configuration stored in Vault KV v2

# ========== OCI Credentials ==========
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

# ========== HCP Configuration & Credentials ==========
# Read/Write access to HCP-related values (vault-radar, project IDs, API tokens, etc)
path "hcp/data/vault-radar" {
  capabilities = ["create", "read", "update", "delete"]
}

path "hcp/metadata/vault-radar" {
  capabilities = ["read"]
}

# Allow listing HCP configurations
path "hcp/metadata" {
  capabilities = ["list"]
}
