# Vault Policy for HCP Terraform to Access OCI Credentials
# This policy grants read access to the OCI credentials stored in Vault
#
# Apply this policy with:
# vault policy write terraform-oci terraform-oci-policy.hcl

# Allow reading the OCI secret data
path "oci/data/terraform" {
  capabilities = ["read"]
}

# Allow reading secret metadata (version info, created time, etc.)
path "oci/metadata/terraform" {
  capabilities = ["read", "list"]
}

# Optional: Allow listing all secrets in the oci mount
# Uncomment if you want to allow listing all secrets
# path "oci/metadata/*" {
#   capabilities = ["list"]
# }
