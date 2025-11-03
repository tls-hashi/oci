# HCP Terraform Workspace Variable Update Required

## Critical Change Needed

You need to **update your workspace variables** in HCP Terraform. The current configuration is incorrect.

## ❌ Current (Incorrect) Configuration

Based on your recent run, you currently have:

| Key | Value | Category |
|-----|-------|----------|
| `vault_backed_dynamic_credentials` | `true` | terraform (HCL) |
| `TFC_VAULT_ADDR` | https://... | env |
| `TFC_VAULT_NAMESPACE` | admin | env |
| `TFC_VAULT_RUN_ROLE` | terraform-oci | env |

## ✅ Required (Correct) Configuration

You need to have these **4 environment variables**:

| Key | Value | Category | Notes |
|-----|-------|----------|-------|
| `TFC_VAULT_PROVIDER_AUTH` | `true` | **env** | ⚠️ ADD THIS - This is the key variable! |
| `TFC_VAULT_ADDR` | `https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200` | env | ✓ Already have |
| `TFC_VAULT_NAMESPACE` | `admin` | env | ✓ Already have |
| `TFC_VAULT_RUN_ROLE` | `terraform-oci` | env | ✓ Already have |

## Action Required

1. **Delete** the Terraform variable: `vault_backed_dynamic_credentials`
2. **Add** the environment variable: `TFC_VAULT_PROVIDER_AUTH` = `true`

### Step-by-Step Instructions

1. Go to: https://app.terraform.io/app/tls-hashi/workspaces/OCI/variables

2. **Delete** this variable:
   - Find `vault_backed_dynamic_credentials` in the Terraform variables section
   - Click the "Delete" button next to it

3. **Add** this variable:
   - In the **Environment variables** section, click "+ Add variable"
   - Key: `TFC_VAULT_PROVIDER_AUTH`
   - Value: `true`
   - Category: **Environment variable** (NOT Terraform variable)
   - Do NOT mark it sensitive
   - Click "Save variable"

### Why This Change?

The official HashiCorp documentation specifies that `TFC_VAULT_PROVIDER_AUTH` must be set to `true` as an **environment variable** to enable dynamic credentials with the Vault provider. The `vault_backed_dynamic_credentials` variable is for Vault-backed dynamic credentials (AWS/Azure/GCP via Vault), not for authenticating to Vault itself.

## After Making Changes

1. Queue a new Terraform plan
2. You should see successful authentication
3. Only the deprecation warning should remain (which is expected and acceptable)

## Expected Result

After this change, your Terraform run should:
- ✅ Successfully authenticate to Vault
- ✅ Read OCI credentials from `oci/data/terraform`
- ⚠️ Show deprecation warning (this is normal and expected)
- ✅ Complete the plan successfully
