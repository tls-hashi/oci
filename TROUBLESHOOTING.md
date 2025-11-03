# Vault Authentication Troubleshooting Guide

This guide addresses the 403 authentication errors when using Vault with HCP Terraform.

## Error Overview

```
Error: failed to lookup token, err=Error making API request.
Code: 403. Errors:
* 2 errors occurred:
  * permission denied
  * invalid token
```

This error indicates that HCP Terraform cannot authenticate to Vault using dynamic credentials (JWT/OIDC).

## Root Causes

1. **JWT auth method not configured** - Vault needs JWT auth enabled and configured for HCP Terraform
2. **Missing or incorrect policy** - The JWT role must be assigned a policy with proper permissions
3. **JWT role not created** - A role must exist that matches HCP Terraform's JWT claims
4. **HCP Terraform workspace not configured** - Workspace needs dynamic credentials enabled

## Solution: Step-by-Step Fix

### Prerequisites

- Access to HCP Vault with admin permissions
- Vault CLI installed and configured
- Access to HCP Terraform workspace settings

### Step 1: Authenticate to Vault

```bash
# Set your Vault environment
export VAULT_ADDR="https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"

# Login to Vault
vault login
```

### Step 2: Run Setup Script

This script will configure everything needed in Vault:

```bash
# Make the script executable
chmod +x setup-vault-jwt-auth.sh

# Run the setup
./setup-vault-jwt-auth.sh
```

The script will:
1. Enable JWT auth method
2. Configure JWT for HCP Terraform (https://app.terraform.io)
3. Create the `terraform-oci` policy
4. Create the `terraform-oci` JWT role
5. Verify the configuration

### Step 3: Configure HCP Terraform Workspace

In your HCP Terraform workspace (`tls-hashi/OCI`):

#### Option A: Using Workspace Variables (Recommended)

1. Go to workspace settings → Variables
2. Add these **Environment Variables**:
   - `TFC_VAULT_ADDR` = `https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200`
   - `TFC_VAULT_NAMESPACE` = `admin`
   - `TFC_VAULT_RUN_ROLE` = `terraform-oci`

3. Add this **Terraform Variable**:
   - `vault_backed_dynamic_credentials` = `true` (HCL)

#### Option B: Using Variable Set (For Multiple Workspaces)

1. Go to Organization settings → Variable Sets
2. Create new Variable Set: `vault-dynamic-credentials`
3. Add the same variables as above
4. Apply to the `OCI` workspace

### Step 4: Verify Vault Setup

Run the verification script to ensure everything is configured correctly:

```bash
# Make the script executable
chmod +x verify-vault-setup.sh

# Run verification
./verify-vault-setup.sh
```

The script checks:
- ✓ Vault authentication
- ✓ JWT auth method enabled
- ✓ terraform-oci policy exists with correct permissions
- ✓ terraform-oci JWT role exists with correct claims
- ✓ OCI credentials exist in Vault
- ✓ Policy permissions are correct

### Step 5: Test Terraform Plan

1. Trigger a new run in HCP Terraform
2. Check the run logs for successful Vault authentication
3. The Terraform plan should now succeed

## Verifying the Fix

After completing the setup, your Terraform run should:

1. **Authenticate successfully**: No more 403 errors
2. **Fetch credentials**: Successfully read from `oci/data/terraform`
3. **Connect to OCI**: OCI provider authenticates using fetched credentials

## Understanding the Configuration

### JWT Auth Flow

1. HCP Terraform generates a JWT token for the workspace run
2. JWT token includes claims like:
   - `aud`: `vault.workload.identity`
   - `sub`: `organization:tls-hashi:project:*:workspace:OCI:run_phase:*`
3. Vault validates the JWT against the configured role
4. If valid, Vault issues a token with the `terraform-oci` policy
5. Terraform uses this token to read OCI credentials

### Policy Permissions

The `terraform-oci` policy grants:
- **Read** access to `oci/data/terraform` (KV v2 data path)
- **Read** access to `oci/metadata/terraform` (for debugging)
- **List** access to `oci/metadata` (for discovery)

### JWT Role Configuration

The `terraform-oci` role binds:
- **Audience**: `vault.workload.identity` (HCP Terraform's JWT audience)
- **Claims**: Matches workspace pattern `organization:tls-hashi:project:*:workspace:OCI:run_phase:*`
- **Policy**: Assigns `terraform-oci` policy
- **TTL**: 20 minutes (sufficient for Terraform runs)

## Common Issues and Solutions

### Issue: "JWT role not found"

**Solution**: The role name in HCP Terraform must match the role name in Vault.
- HCP Terraform: `TFC_VAULT_RUN_ROLE=terraform-oci`
- Vault: `auth/jwt/role/terraform-oci`

### Issue: "Permission denied" after successful auth

**Solution**: The policy doesn't grant read access to the required path.
- Verify policy with: `vault policy read terraform-oci`
- Ensure path `oci/data/terraform` has `["read"]` capability

### Issue: "Bound claims do not match"

**Solution**: The JWT claims from HCP Terraform don't match the role's bound_claims.
- Review role: `vault read auth/jwt/role/terraform-oci`
- Ensure pattern matches: `organization:tls-hashi:project:*:workspace:OCI:run_phase:*`

### Issue: "OCI credentials not found"

**Solution**: Credentials aren't stored at the expected path.
- Store credentials at: `vault kv put -mount=oci terraform key=value`
- Required keys: `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key`, `compartment_ocid`, `region`

## Deprecation Warning

The `vault_kv_secret_v2` data source is deprecated, but intentionally used here because:

1. OCI credentials must persist in Terraform state
2. The OCI provider requires these credentials throughout the run
3. Ephemeral resources would not work for this use case

This is a known limitation and the data source continues to work despite the deprecation warning.

## Additional Resources

- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/vault-backed)
- [Vault JWT Auth](https://developer.hashicorp.com/vault/docs/auth/jwt)
- [HCP Vault Documentation](https://developer.hashicorp.com/hcp/docs/vault)

## Files Created

- `terraform-oci-policy.hcl` - Vault policy definition
- `setup-vault-jwt-auth.sh` - Automated setup script
- `verify-vault-setup.sh` - Verification script
- `TROUBLESHOOTING.md` - This documentation

## Need Help?

If you continue to experience issues:

1. Run `./verify-vault-setup.sh` and share output
2. Check HCP Terraform run logs for detailed error messages
3. Verify HCP Vault cluster is accessible from HCP Terraform
