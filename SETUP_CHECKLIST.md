# HCP Vault Dynamic Credentials - Setup Checklist

This checklist will help you complete the Vault integration setup. Follow these steps in order.

## Status: Configuration Complete, Vault Setup Required

### ✅ Completed Steps

- [x] Vault.tf created with provider configuration
- [x] All Terraform code updated to use Vault credentials
- [x] Documentation created
- [x] Test scripts created
- [x] Code committed to Git
- [x] Secrets stored in Vault at `oci/terraform`
- [x] Vault policy created

### ⏳ Remaining Steps

## Step 1: Create JWT Auth Role in Vault

**Status:** ❌ Not completed (test shows "JWT role 'tfc-oci' not found")

Run this command in your Vault cluster:

```bash
vault write auth/jwt/role/tfc-oci \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  bound_claims_type="glob" \
  bound_claims="sub=organization:tls-hashi:project:*:workspace:OCI:run_phase:*" \
  user_claim="terraform_full_workspace" \
  policies="terraform-oci" \
  ttl="20m"
```

**Verify:**
```bash
vault read auth/jwt/role/tfc-oci
```

Expected output should show the role configuration.

---

## Step 2: Configure HCP Terraform Workspace Variables

**Status:** ❌ Not completed (error shows "no vault token set on Client")

Go to your HCP Terraform workspace: `https://app.terraform.io/app/tls-hashi/workspaces/OCI/variables`

Add these **Environment Variables** (not Terraform variables):

| Variable Name | Value | Category | Sensitive |
|--------------|-------|----------|-----------|
| TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS | `true` | Environment | No |
| TFC_VAULT_ADDR | `https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200` | Environment | No |
| TFC_VAULT_NAMESPACE | `admin` | Environment | No |
| TFC_VAULT_RUN_ROLE | `tfc-oci` | Environment | No |

**Important:** 
- These MUST be **Environment Variables**, not Terraform Variables
- The category dropdown should say "Environment variable"

---

## Step 3: Remove or Update terraform.tfvars File

**Status:** ⚠️ Warning detected (undeclared variable "region" in terraform.tfvars)

You have a `terraform.tfvars` file in your HCP Terraform workspace that contains a `region` variable. Since we're now getting the region from Vault, you should either:

**Option A: Remove the terraform.tfvars file** (if it's in the workspace, not git)
- Go to workspace Settings > Variables
- Delete any Terraform variables for credentials (tenancy_ocid, user_ocid, etc.)

**Option B: If terraform.tfvars is in git, update it:**
```bash
# Remove credential-related variables from terraform.tfvars if they exist
# Keep only non-sensitive configuration variables
```

---

## Step 4: Verify the Setup

### 4.1 Run Local Tests

```bash
# Should pass all tests
./tests/test-vault-dynamic-creds.sh
```

Expected output:
```
✓ Vault server is reachable
✓ Secret exists at oci/terraform
✓ All required fields present
✓ Private key has correct format
✓ JWT role 'tfc-oci' is configured  ← This should pass after Step 1
✓ Policy 'terraform-oci' exists
```

### 4.2 Test in HCP Terraform

```bash
# Push your changes if not already pushed
git push

# Then in HCP Terraform UI:
# 1. Go to your workspace
# 2. Click "Actions" > "Start new plan"
# 3. Monitor the logs
```

**Expected Success Output:**
```
Initializing plugins and modules...
data.vault_kv_secret_v2.oci: Refreshing...
data.oci_identity_availability_domains.ads: Reading...
```

**If you see errors:**
- "no vault token set on Client" → Step 2 not completed
- "permission denied" → Check Vault policy in Step 1
- "JWT role not found" → Step 1 not completed

---

## Troubleshooting Common Issues

### Error: "no vault token set on Client"

**Cause:** HCP Terraform dynamic credentials not configured

**Fix:** Complete Step 2 above - add the TFC_VAULT_* environment variables

### Error: "JWT role 'tfc-oci' not found"

**Cause:** JWT role not created in Vault

**Fix:** Complete Step 1 above - create the JWT role

### Warning: "undeclared variable 'region'"

**Cause:** Old terraform.tfvars file or workspace variables

**Fix:**
1. Go to workspace Settings > Variables
2. Remove any Terraform variables for: region, tenancy_ocid, user_ocid, fingerprint, private_key, compartment_ocid
3. These are now retrieved from Vault automatically

### Error: "permission denied" from Vault

**Cause:** Policy or JWT role misconfigured

**Fix:**
1. Verify policy exists: `vault policy read terraform-oci`
2. Verify JWT role: `vault read auth/jwt/role/tfc-oci`
3. Check the role's policies include "terraform-oci"
4. Verify bound_claims matches your organization and workspace

---

## Quick Command Reference

```bash
# Check if JWT role exists
vault read auth/jwt/role/tfc-oci

# Check if policy exists  
vault policy read terraform-oci

# Check if secret exists
vault kv get oci/terraform

# Run test suite
./tests/test-vault-dynamic-creds.sh

# View Vault audit logs (if needed)
# Available in HCP Vault UI
```

---

## Success Criteria

When everything is working, you should see:

1. ✅ Test script passes all 6 tests
2. ✅ HCP Terraform plan runs without "no vault token" errors
3. ✅ Vault data source refreshes successfully
4. ✅ No warnings about undeclared variables
5. ✅ OCI provider initializes with credentials from Vault

---

## Summary

**What's Complete:**
- All Terraform code configured for Vault integration
- Documentation and test scripts ready
- Secrets stored in Vault
- Vault policy created

**What You Need to Do:**
1. Create JWT auth role in Vault (1 command)
2. Add 4 environment variables to HCP Terraform workspace
3. Remove old credential variables from workspace
4. Test and verify

**Estimated Time:** 10-15 minutes

**Questions?** See `HCP_VAULT_DYNAMIC_CREDENTIALS_SETUP.md` for detailed instructions.
