# HCP Vault Integration Summary

## What Was Implemented

This project now uses **HCP Vault Dedicated** with **HCP Terraform Dynamic Credentials** to securely manage and retrieve OCI authentication credentials, instead of storing them as plain-text variables in HCP Terraform.

## Architecture Overview

```
┌─────────────────────┐
│  HCP Terraform      │
│  Workspace          │
│  (OCI)             │
└──────────┬──────────┘
           │
           │ JWT Token (OIDC)
           │ Automatic Auth
           ▼
┌─────────────────────┐
│  HCP Vault         │
│  Dedicated         │
│  (tls-hashi-kv)   │
└──────────┬──────────┘
           │
           │ Returns Secrets
           │ (KV v2)
           ▼
┌─────────────────────┐
│ OCI Credentials     │
│ - tenancy_ocid      │
│ - user_ocid         │
│ - fingerprint       │
│ - private_key       │
│ - compartment_ocid  │
│ - region            │
└─────────────────────┘
```

## Key Components

### 1. Vault Configuration (`vault.tf`)

```hcl
provider "vault" {
  address   = "https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
  namespace = "admin"
  # Authentication handled automatically by HCP Terraform Dynamic Credentials
}

data "vault_kv_secret_v2" "oci" {
  mount = "oci"
  name  = "terraform"
}

locals {
  oci_creds = data.vault_kv_secret_v2.oci.data
  # Credentials extracted and used throughout configuration
}
```

### 2. Provider Configuration (`main.tf`)

```hcl
provider "oci" {
  tenancy_ocid = local.tenancy_ocid
  user_ocid    = local.user_ocid
  fingerprint  = local.fingerprint
  private_key  = local.private_key
  region       = local.region
}
```

### 3. HCP Terraform Environment Variables

Required in your HCP Terraform workspace:

- `TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS = true`
- `TFC_VAULT_ADDR = https://your-vault-cluster.hashicorp.cloud:8200`
- `TFC_VAULT_NAMESPACE = admin`
- `TFC_VAULT_RUN_ROLE = tfc-oci`

## Security Benefits

1. **No Credential Exposure**: Credentials never stored in HCP Terraform variables or state files
2. **Automatic Rotation**: Update credentials in Vault without touching Terraform configuration
3. **Audit Trail**: All credential access logged in Vault audit logs
4. **Least Privilege**: Fine-grained access control via Vault policies
5. **Time-Limited Access**: JWT tokens have configurable TTL (default 20 minutes)

## Setup Requirements

### In HCP Vault

1. ✅ KV v2 secrets engine enabled at path `oci`
2. ✅ OCI credentials stored at `oci/terraform`
3. ☐ JWT auth method configured for HCP Terraform
4. ☐ Vault policy `terraform-oci` created and applied
5. ☐ JWT role `tfc-oci` configured with correct bound_claims

### In HCP Terraform

1. ✅ Workspace created and configured
2. ☐ Environment variables set for dynamic credentials
3. ☐ Terraform code pushed and initialized

## Next Steps to Complete Setup

### Step 1: Configure Vault JWT Authentication

```bash
# Enable JWT auth
vault auth enable jwt

# Configure for HCP Terraform
vault write auth/jwt/config \
  bound_issuer="https://app.terraform.io" \
  oidc_discovery_url="https://app.terraform.io"

# Create role (replace tls-hashi with your org, OCI with your workspace)
vault write auth/jwt/role/tfc-oci \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  bound_claims_type="glob" \
  bound_claims='{"sub":"organization:tls-hashi:project:*:workspace:OCI:run_phase:*"}' \
  user_claim="terraform_full_workspace" \
  policies="terraform-oci" \
  ttl="20m"
```

### Step 2: Apply Vault Policy

```bash
vault policy write terraform-oci vault-policies/terraform-oci-policy.hcl
```

### Step 3: Configure HCP Terraform Workspace

Navigate to your workspace **Settings > Variables** and add:

| Variable | Value | Type | Sensitive |
|----------|-------|------|-----------|
| TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS | true | Environment | No |
| TFC_VAULT_ADDR | https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200 | Environment | No |
| TFC_VAULT_NAMESPACE | admin | Environment | No |
| TFC_VAULT_RUN_ROLE | tfc-oci | Environment | No |

### Step 4: Test the Configuration

```bash
# Run the automated test suite
chmod +x tests/test-vault-dynamic-creds.sh
./tests/test-vault-dynamic-creds.sh

# Test Terraform plan
terraform init
terraform plan
```

### Step 5: Verify in HCP Terraform

1. Push your changes to Git
2. Trigger a plan in HCP Terraform
3. Monitor the logs for successful Vault authentication
4. Look for: `data.vault_kv_secret_v2.oci: Refreshing...`

## Files Modified

### Configuration Files
- ✅ `vault.tf` - Vault provider and data source configuration
- ✅ `main.tf` - Updated to use Vault-sourced credentials
- ✅ `variables.tf` - Commented out credential variables
- ✅ `dns.tf` - Updated to use `local.compartment_ocid`
- ✅ `network.tf` - Updated to use `local.compartment_ocid`

### Documentation
- ✅ `HCP_VAULT_DYNAMIC_CREDENTIALS_SETUP.md` - Complete setup guide
- ✅ `VAULT_INTEGRATION_SUMMARY.md` - This file

### Testing & Policies
- ✅ `tests/test-vault-dynamic-creds.sh` - Automated test script
- ✅ `vault-policies/terraform-oci-policy.hcl` - Vault policy template

## Troubleshooting Guide

### Common Errors

#### "no vault token set on Client"
**Solution**: Ensure all TFC_VAULT_* environment variables are set in workspace

#### "permission denied"
**Solution**: Verify Vault policy and JWT role configuration

#### "failed to configure Vault address"
**Solution**: Check TFC_VAULT_ADDR is correct and includes port :8200

### Testing Checklist

- [ ] Vault server is reachable
- [ ] Secret exists at `oci/terraform`
- [ ] All required fields present in secret
- [ ] Private key has correct format
- [ ] JWT auth method enabled
- [ ] JWT role `tfc-oci` exists
- [ ] Policy `terraform-oci` exists
- [ ] HCP Terraform environment variables set
- [ ] Terraform plan succeeds

## Security Best Practices

1. **Rotate Credentials Regularly**
   ```bash
   vault kv put oci/terraform \
     tenancy_ocid="new_value" \
     # ... other fields
   ```

2. **Monitor Audit Logs**
   - Review Vault audit logs for unauthorized access attempts
   - Set up alerts for suspicious activity

3. **Use Least Privilege**
   - Grant minimum required permissions in Vault policies
   - Use workspace-specific JWT roles when possible

4. **Backup Critical Secrets**
   ```bash
   vault kv get -format=json oci/terraform > backup.json.encrypted
   gpg -c backup.json.encrypted
   ```

5. **Regular Security Reviews**
   - Audit Vault policies quarterly
   - Review JWT role configurations
   - Verify access patterns in logs

## Additional Resources

- [HCP Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Vault KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
- [JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)

## Support

For issues related to:
- **Vault Configuration**: Check `HCP_VAULT_DYNAMIC_CREDENTIALS_SETUP.md`
- **Testing**: Run `tests/test-vault-dynamic-creds.sh`
- **Policies**: Review `vault-policies/terraform-oci-policy.hcl`

---

**Status**: ✅ Configuration Complete - Awaiting Vault JWT Setup  
**Last Updated**: November 2, 2025  
**Maintained By**: Infrastructure Team
