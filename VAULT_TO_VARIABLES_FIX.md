# Fix: HCP Terraform Configuration - Vault to Variables Migration

## Problem Summary

The HCP Terraform configuration was attempting to use HashiCorp Vault for OCI credentials, but this integration was not properly configured in HCP Terraform. The errors included:

1. **No Vault token**: HCP Terraform couldn't authenticate to Vault
2. **Missing variable declarations**: All OCI authentication variables were commented out
3. **Invalid provider configuration**: OCI provider couldn't find tenancy configuration
4. **Undeclared region variable**: Warning about region variable in terraform.tfvars

## Root Cause

The configuration was designed to pull credentials from Vault using the `vault_kv_secret_v2` data source, but:
- HCP Terraform workspaces don't automatically have Vault integration enabled
- There's no "Connect to Vault" option in the HCP Terraform UI (this would require Dynamic Credentials setup)
- The variable declarations in `variables.tf` were all commented out

## Solution Implemented

### 1. Removed Vault Integration

**Changed files:**
- `vault.tf` → renamed to `vault.tf.disabled`
- `main.tf` → removed Vault provider from required_providers
- All references to `local.oci_creds.*` changed to `var.*`
- All references to `local.compartment_ocid` changed to `var.compartment_ocid`

### 2. Enabled Variable Declarations

**Updated `variables.tf`:**
- Uncommented all OCI authentication variable declarations:
  - `tenancy_ocid`
  - `user_ocid`
  - `fingerprint`
  - `private_key`
  - `compartment_ocid`
  - `region`

### 3. Updated Resource References

**Updated files:**
- `main.tf` - OCI provider and data sources
- `dns.tf` - DNS zone configuration
- `network.tf` - All network resources

Changed all `local.compartment_ocid` and `local.oci_creds.*` references to use variables directly.

## How to Configure

### In HCP Terraform Workspace

You need to set these variables in your HCP Terraform workspace:

**Settings > Variables > Add Variable**

#### Terraform Variables (mark as Sensitive)

| Variable Name | Type | Sensitive | Description |
|--------------|------|-----------|-------------|
| `tenancy_ocid` | String | ✓ | Your OCI tenancy OCID |
| `user_ocid` | String | ✓ | Your OCI user OCID |
| `fingerprint` | String | ✓ | API key fingerprint |
| `private_key` | String | ✓ | Complete private key (include BEGIN/END) |
| `compartment_ocid` | String | ✗ | Compartment OCID |
| `region` | String | ✗ | OCI region (e.g., us-phoenix-1) |

#### Optional Variables

| Variable Name | Default | Description |
|--------------|---------|-------------|
| `vcn_cidr` | 10.0.0.0/16 | VCN CIDR block |
| `public_subnet_cidr` | 10.0.1.0/24 | Public subnet CIDR |
| `private_subnet_cidr` | 10.0.2.0/24 | Private subnet CIDR |
| `naming_prefix` | twotwotwo | Resource name prefix |
| `environment` | prod | Environment name |
| `dns_zone_name` | 2two2.me | DNS zone name |

### Finding OCI Credentials

1. **Tenancy OCID**: OCI Console → Identity → Tenancy Information
2. **User OCID**: OCI Console → Identity → Users → Your User
3. **Fingerprint**: OCI Console → Identity → Users → Your User → API Keys
4. **Private Key**: Content of your `.pem` file (must include `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines)
5. **Compartment OCID**: OCI Console → Identity → Compartments
6. **Region**: Your preferred region identifier

## Verification

After applying these changes, run:

```bash
terraform init
terraform plan
```

The plan should now succeed and show the infrastructure changes without Vault-related errors.

## Alternative: Using Vault (Advanced)

If you want to use Vault integration in the future, you would need to:

1. Set up HCP Terraform Dynamic Credentials for Vault
2. Configure the Vault provider with proper authentication
3. Re-enable `vault.tf` (rename from `.disabled`)
4. Add Vault provider back to `required_providers` in `main.tf`
5. Revert variable references back to `local.oci_creds.*`

This is more complex and requires proper Vault setup. For most users, using HCP Terraform variables directly is the simpler and recommended approach.

## Files Changed

- `variables.tf` - Uncommented variable declarations
- `main.tf` - Removed Vault provider, updated references
- `dns.tf` - Updated compartment_id reference
- `network.tf` - Updated all compartment_id references
- `vault.tf` - Renamed to `vault.tf.disabled`

## Next Steps

1. Set all required variables in your HCP Terraform workspace
2. Run `terraform plan` to verify the configuration
3. Review the plan output
4. Apply the changes with `terraform apply` when ready
