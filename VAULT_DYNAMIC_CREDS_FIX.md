# Vault Dynamic Credentials Configuration Fix

## Issues Fixed

### Issue 1: Vault Provider Configuration
**Problem:** The Vault provider was explicitly configured with `address` and `namespace`, which prevented HCP Terraform's dynamic credentials from injecting authentication automatically.

**Fix:** Removed explicit configuration to allow HCP Terraform to manage authentication via environment variables.

**Changed in:** `vault.tf`

```hcl
# Before (incorrect):
provider "vault" {
  address   = "https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
  namespace = "admin"
}

# After (correct):
provider "vault" {
  # Configuration automatically provided by HCP Terraform Dynamic Credentials
  # via environment variables
}
```

### Issue 2: Region Variable Declaration
**Problem:** The `region` variable was commented out in `variables.tf`, but `terraform.tfvars.example` still referenced it, causing a warning.

**Fix:** Removed `region` from the example tfvars file since it's now sourced from Vault via `local.region`.

**Changed in:** `terraform.tfvars.example`

## Required HCP Terraform Workspace Configuration

Ensure these **Environment Variables** are set in your HCP Terraform workspace:

| Variable Name | Value | Type |
|--------------|-------|------|
| `TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS` | `true` | Environment Variable |
| `TFC_VAULT_ADDR` | `https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200` | Environment Variable |
| `TFC_VAULT_NAMESPACE` | `admin` | Environment Variable |
| `TFC_VAULT_RUN_ROLE` | `tfc-oci` | Environment Variable |

### Verification Steps

1. **Check workspace variables:**
   - Go to HCP Terraform: https://app.terraform.io
   - Navigate to: Organization `tls-hashi` → Workspace `OCI`
   - Click: Settings → Variables
   - Verify all 4 environment variables exist

2. **Remove any Terraform variables for OCI credentials:**
   - Delete any workspace Terraform variables for: `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key`, `compartment_ocid`, `region`
   - These are now retrieved from Vault automatically

3. **Trigger a new plan:**
   ```bash
   # Commit and push changes
   git add vault.tf terraform.tfvars.example
   git commit -m "Fix Vault dynamic credentials configuration"
   git push
   ```

4. **Monitor the run in HCP Terraform:**
   - Look for successful Vault authentication
   - Verify OCI provider initialization succeeds

## What Should Happen Now

When you trigger a plan in HCP Terraform:

1. ✅ HCP Terraform generates a JWT token
2. ✅ The Vault provider authenticates using the JWT token via the `tfc-oci` role
3. ✅ The `data.vault_kv_secret_v2.oci` resource fetches credentials from Vault
4. ✅ The OCI provider initializes with credentials from Vault
5. ✅ Terraform plan executes successfully

## Expected Output

```
data.vault_kv_secret_v2.oci: Reading...
data.vault_kv_secret_v2.oci: Read complete after 1s

Terraform will perform the following actions:
  # ... your infrastructure plan ...
```

## Troubleshooting

### If you still see "no vault token set on Client"

1. Double-check environment variables are set as **Environment Variables** (not Terraform variables)
2. Verify variable names are exact (including `TFC_` prefix)
3. Ensure the workspace name in the JWT role matches: `OCI`

### If you see "permission denied"

1. Verify the JWT role `tfc-oci` exists:
   ```bash
   vault read auth/jwt/role/tfc-oci
   ```

2. Check the policy allows reading the secret:
   ```bash
   vault policy read terraform-oci
   ```

### To test JWT role configuration:

```bash
vault read auth/jwt/role/tfc-oci
```

Expected output should include:
```
bound_audiences        [vault.workload.identity]
bound_claims           map[sub:organization:tls-hashi:project:*:workspace:OCI:run_phase:*]
policies               [terraform-oci]
```

## Summary

The configuration now properly uses HCP Terraform's dynamic credentials feature to:
- ✅ Authenticate to Vault without storing tokens
- ✅ Retrieve OCI credentials securely from Vault
- ✅ Avoid storing sensitive credentials in Terraform variables

All OCI authentication is handled via Vault at runtime, with no static credentials stored in HCP Terraform.
