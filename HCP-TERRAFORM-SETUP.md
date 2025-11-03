# HCP Terraform Workspace Configuration

Your Vault setup is complete! Now configure your HCP Terraform workspace to authenticate using dynamic credentials.

## Workspace: tls-hashi/OCI

### Step 1: Navigate to Workspace Settings

1. Go to https://app.terraform.io/app/tls-hashi/workspaces/OCI
2. Click **Settings** → **Variables**

### Step 2: Add Environment Variables

Add these **Environment Variables** (NOT Terraform variables):

| Key | Value | Sensitive |
|-----|-------|-----------|
| `TFC_VAULT_ADDR` | `https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200` | No |
| `TFC_VAULT_NAMESPACE` | `admin` | No |
| `TFC_VAULT_RUN_ROLE` | `terraform-oci` | No |

### Step 3: Enable Dynamic Credentials

Add this **Terraform Variable**:

| Key | Value | HCL | Sensitive |
|-----|-------|-----|-----------|
| `vault_backed_dynamic_credentials` | `true` | ✓ Yes | No |

**Important:** Make sure to check the "HCL" checkbox for this variable.

### Alternative: Use a Variable Set (Recommended for Multiple Workspaces)

If you have multiple workspaces that need Vault access:

1. Go to **Organization Settings** → **Variable Sets**
2. Click **Create variable set**
3. Name: `vault-dynamic-credentials`
4. Add the 4 variables listed above
5. Under **Variable Set Scope**, apply to workspaces:
   - Select **Apply to specific workspaces**
   - Choose **OCI** workspace

## Step 4: Test the Configuration

1. Queue a new Terraform plan in the workspace
2. Monitor the run logs
3. You should see successful Vault authentication
4. The plan should proceed without the 403 error

## Expected Run Output

You should see in the logs:
```
Initializing Vault client...
Successfully authenticated to Vault using dynamic credentials
Reading OCI credentials from Vault...
Successfully retrieved credentials from oci/data/terraform
```

## Troubleshooting

### Issue: Still getting 403 errors

**Check:**
- All 4 variables are set correctly (no typos)
- `vault_backed_dynamic_credentials` has HCL checkbox enabled
- Variables are Environment Variables (not Terraform variables) except for `vault_backed_dynamic_credentials`

### Issue: "JWT role not found"

**Check:**
- `TFC_VAULT_RUN_ROLE` exactly matches the role name in Vault: `terraform-oci`
- Run `./verify-vault-setup.sh` to confirm the role exists

### Issue: "Permission denied" after authentication

**Check:**
- Run `./verify-vault-setup.sh` to verify policy permissions
- Ensure OCI credentials are stored at the correct path in Vault

## Architecture Overview

```
HCP Terraform Workspace
    ↓ (generates JWT token)
Vault JWT Auth
    ↓ (validates JWT claims)
Vault Token with terraform-oci policy
    ↓ (reads secrets)
OCI Credentials at oci/data/terraform
    ↓ (passed to)
Terraform OCI Provider
    ↓ (provisions)
Oracle Cloud Infrastructure
```

## Reference

- **Vault Address**: https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200
- **Vault Namespace**: admin
- **JWT Auth Path**: auth/jwt
- **JWT Role**: terraform-oci
- **Policy**: terraform-oci
- **Secret Path**: oci/data/terraform

## Documentation

- See `TROUBLESHOOTING.md` for detailed troubleshooting steps
- See `verify-vault-setup.sh` to verify Vault configuration
- Run `./verify-vault-setup.sh` anytime to check your setup
