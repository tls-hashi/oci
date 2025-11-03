# HCP Vault Dynamic Credentials Setup Guide

This guide explains how to configure HCP Terraform to use dynamic credentials with HCP Vault Dedicated to retrieve OCI credentials securely.

## Overview

Instead of storing sensitive OCI credentials directly in HCP Terraform variables, this setup:
1. Stores credentials securely in HCP Vault
2. Uses HCP Terraform's Dynamic Credentials feature to authenticate to Vault
3. Retrieves credentials at runtime during Terraform operations
4. Never exposes credentials in plain text

## Prerequisites

- HCP Vault Dedicated cluster running
- HCP Terraform workspace configured
- Admin access to both HCP Vault and HCP Terraform
- OCI API credentials (tenancy_ocid, user_ocid, fingerprint, private_key, compartment_ocid, region)

## Part 1: Configure HCP Vault

### Step 1: Enable KV v2 Secrets Engine

```bash
# Authenticate to your HCP Vault cluster
vault login

# Enable KV v2 secrets engine at path 'oci'
vault secrets enable -path=oci kv-v2
```

### Step 2: Store OCI Credentials in Vault

```bash
# Store all OCI credentials in a single secret
vault kv put oci/terraform \
  tenancy_ocid="ocid1.tenancy.oc1..aaaa..." \
  user_ocid="ocid1.user.oc1..aaaa..." \
  fingerprint="xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx" \
  private_key="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
-----END RSA PRIVATE KEY-----" \
  compartment_ocid="ocid1.compartment.oc1..aaaa..." \
  region="us-phoenix-1"
```

**Important Notes:**
- The private_key must include the full RSA key with BEGIN/END markers
- Use quotes around multi-line values
- Escape special characters if needed

### Step 3: Create Vault Policy for Terraform

Create a policy file `terraform-oci-policy.hcl`:

```hcl
# Policy for HCP Terraform to read OCI credentials
path "oci/data/terraform" {
  capabilities = ["read"]
}

path "oci/metadata/terraform" {
  capabilities = ["read", "list"]
}
```

Apply the policy:

```bash
vault policy write terraform-oci terraform-oci-policy.hcl
```

### Step 4: Configure JWT Auth Method for HCP Terraform

**Important:** HCP Terraform uses JWT (OIDC) authentication for dynamic credentials.

```bash
# Enable JWT auth method
vault auth enable jwt

# Configure JWT auth for HCP Terraform
vault write auth/jwt/config \
  bound_issuer="https://app.terraform.io" \
  oidc_discovery_url="https://app.terraform.io"

# Create a role for your HCP Terraform organization and workspace
vault write auth/jwt/role/tfc-oci \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  bound_claims_type="glob" \
  bound_claims='{"sub":"organization:tls-hashi:project:*:workspace:OCI:run_phase:*"}' \
  user_claim="terraform_full_workspace" \
  policies="terraform-oci" \
  ttl="20m"
```

**Important Configuration Notes:**
- Replace `tls-hashi` with your HCP Terraform organization name
- Replace `OCI` with your workspace name
- The `bound_claims` pattern allows any project within the organization
- TTL of 20m is sufficient for most Terraform runs

### Step 5: Verify Vault Setup

```bash
# Verify the secret exists
vault kv get oci/terraform

# Verify the policy
vault policy read terraform-oci

# Verify the JWT role
vault read auth/jwt/role/tfc-oci
```

## Part 2: Configure HCP Terraform Dynamic Credentials

### Step 1: Get Your Vault Information

You'll need:
- **Vault Address**: `https://your-cluster.hashicorp.cloud:8200`
- **Vault Namespace**: Usually `admin` for HCP Vault Dedicated
- **JWT Role**: `tfc-oci` (the role we created above)

### Step 2: Configure Workspace Environment Variables

In your HCP Terraform workspace, go to **Settings > Variables** and add these **Environment Variables**:

| Variable Name | Value | Sensitive | Description |
|--------------|-------|-----------|-------------|
| `TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS` | `true` | No | Enable Vault dynamic credentials |
| `TFC_VAULT_ADDR` | Your Vault address | No | HCP Vault cluster URL |
| `TFC_VAULT_NAMESPACE` | `admin` | No | Vault namespace |
| `TFC_VAULT_RUN_ROLE` | `tfc-oci` | No | JWT auth role name |

**Example values:**
```
TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS = true
TFC_VAULT_ADDR = https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200
TFC_VAULT_NAMESPACE = admin
TFC_VAULT_RUN_ROLE = tfc-oci
```

### Step 3: Alternative - Use Variable Sets (Recommended for Multiple Workspaces)

If you have multiple workspaces that need Vault access:

1. Go to **Organization Settings > Variable Sets**
2. Click **Create variable set**
3. Name it "HCP Vault Dynamic Credentials"
4. Add the same environment variables as above
5. Apply to workspaces: Select "Apply to specific workspaces" and choose your workspace(s)

## Part 3: Testing the Configuration

### Test 1: Verify Vault Connectivity (Local)

Create a test script `test-vault-connection.sh`:

```bash
#!/bin/bash

# Test Vault connection and secret retrieval
VAULT_ADDR="https://your-vault-cluster.hashicorp.cloud:8200"
VAULT_NAMESPACE="admin"

echo "Testing Vault connection..."
vault status -address=$VAULT_ADDR -namespace=$VAULT_NAMESPACE

echo -e "\nTesting secret retrieval..."
vault kv get -address=$VAULT_ADDR -namespace=$VAULT_NAMESPACE oci/terraform

echo -e "\nTest complete!"
```

Run the test:
```bash
chmod +x test-vault-connection.sh
./test-vault-connection.sh
```

### Test 2: Verify Terraform Configuration (Local)

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Check that Terraform can read the configuration
# (This won't test Vault auth, but will verify syntax)
terraform plan
```

### Test 3: Test in HCP Terraform

1. **Commit and push your changes:**
   ```bash
   git add .
   git commit -m "Configure HCP Vault dynamic credentials"
   git push
   ```

2. **Trigger a plan in HCP Terraform:**
   - Go to your workspace in HCP Terraform
   - Click "Actions > Start new plan"
   - Or trigger via CLI: `terraform plan`

3. **Monitor the run:**
   - Watch for successful Vault authentication in the logs
   - Look for messages like:
     ```
     Initializing plugins and modules...
     data.vault_kv_secret_v2.oci: Refreshing...
     ```

4. **Check for errors:**
   - **"no vault token set on Client"**: Dynamic credentials not configured correctly
   - **"permission denied"**: Vault policy is too restrictive
   - **"failed to configure Vault address"**: Check TFC_VAULT_ADDR variable

### Test 4: Automated Testing Script

Create `tests/test-vault-dynamic-creds.sh`:

```bash
#!/bin/bash
set -e

echo "=== HCP Vault Dynamic Credentials Test Suite ==="
echo ""

# Configuration
VAULT_ADDR="${TFC_VAULT_ADDR:-https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200}"
VAULT_NAMESPACE="${TFC_VAULT_NAMESPACE:-admin}"
SECRET_PATH="oci/terraform"

echo "Test 1: Vault Server Connectivity"
echo "-----------------------------------"
if vault status -address="$VAULT_ADDR" -namespace="$VAULT_NAMESPACE" > /dev/null 2>&1; then
    echo "✓ Vault server is reachable"
else
    echo "✗ Failed to connect to Vault server"
    exit 1
fi
echo ""

echo "Test 2: Secret Existence"
echo "-------------------------"
if vault kv get -address="$VAULT_ADDR" -namespace="$VAULT_NAMESPACE" "$SECRET_PATH" > /dev/null 2>&1; then
    echo "✓ Secret exists at $SECRET_PATH"
else
    echo "✗ Secret not found at $SECRET_PATH"
    exit 1
fi
echo ""

echo "Test 3: Required Fields Validation"
echo "------------------------------------"
SECRET_DATA=$(vault kv get -format=json -address="$VAULT_ADDR" -namespace="$VAULT_NAMESPACE" "$SECRET_PATH")

REQUIRED_FIELDS=("tenancy_ocid" "user_ocid" "fingerprint" "private_key" "compartment_ocid" "region")
ALL_PRESENT=true

for field in "${REQUIRED_FIELDS[@]}"; do
    if echo "$SECRET_DATA" | jq -e ".data.data.${field}" > /dev/null 2>&1; then
        echo "✓ Field '$field' present"
    else
        echo "✗ Field '$field' missing"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    exit 1
fi
echo ""

echo "Test 4: Private Key Format"
echo "---------------------------"
PRIVATE_KEY=$(echo "$SECRET_DATA" | jq -r '.data.data.private_key')
if echo "$PRIVATE_KEY" | grep -q "BEGIN RSA PRIVATE KEY"; then
    echo "✓ Private key has correct format"
else
    echo "✗ Private key format invalid"
    exit 1
fi
echo ""

echo "Test 5: JWT Auth Configuration"
echo "--------------------------------"
if vault read -address="$VAULT_ADDR" -namespace="$VAULT_NAMESPACE" auth/jwt/role/tfc-oci > /dev/null 2>&1; then
    echo "✓ JWT role 'tfc-oci' is configured"
else
    echo "✗ JWT role 'tfc-oci' not found"
    exit 1
fi
echo ""

echo "Test 6: Policy Validation"
echo "---------------------------"
if vault policy read -address="$VAULT_ADDR" -namespace="$VAULT_NAMESPACE" terraform-oci > /dev/null 2>&1; then
    echo "✓ Policy 'terraform-oci' exists"
else
    echo "✗ Policy 'terraform-oci' not found"
    exit 1
fi
echo ""

echo "=== All tests passed! ==="
```

Run the tests:
```bash
chmod +x tests/test-vault-dynamic-creds.sh
./tests/test-vault-dynamic-creds.sh
```

### Test 5: Manual Integration Test

1. **Create a test workspace:**
   ```bash
   # In HCP Terraform, create a new workspace for testing
   # Use the same configuration but different workspace name
   ```

2. **Apply minimal configuration:**
   ```bash
   # Test just the Vault data source
   terraform init
   terraform plan -target=data.vault_kv_secret_v2.oci
   ```

3. **Verify output:**
   ```bash
   # Check terraform state for the secret
   terraform state show data.vault_kv_secret_v2.oci
   ```

## Part 4: Troubleshooting

### Common Issues and Solutions

#### Issue 1: "no vault token set on Client"

**Cause:** Dynamic credentials not properly configured.

**Solution:**
1. Verify environment variables in HCP Terraform workspace:
   ```
   TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS = true
   TFC_VAULT_ADDR = <your-vault-address>
   TFC_VAULT_NAMESPACE = admin
   TFC_VAULT_RUN_ROLE = tfc-oci
   ```

2. Check that all variables are set as **Environment Variables**, not Terraform Variables

3. Verify the workspace name in the JWT role matches your actual workspace

#### Issue 2: "permission denied"

**Cause:** Vault policy insufficient or JWT role misconfigured.

**Solution:**
1. Verify the policy allows reading the secret:
   ```bash
   vault policy read terraform-oci
   ```

2. Check the JWT role bound_claims matches your organization and workspace:
   ```bash
   vault read auth/jwt/role/tfc-oci
   ```

3. Update bound_claims if needed:
   ```bash
   vault write auth/jwt/role/tfc-oci \
     bound_claims='{"sub":"organization:YOUR_ORG:project:*:workspace:YOUR_WORKSPACE:run_phase:*"}'
   ```

#### Issue 3: "failed to configure Vault address"

**Cause:** Vault address incorrect or unreachable.

**Solution:**
1. Verify the Vault address is correct and includes the port:
   ```
   https://your-cluster.hashicorp.cloud:8200
   ```

2. Test connectivity from your local machine:
   ```bash
   curl -k https://your-cluster.hashicorp.cloud:8200/v1/sys/health
   ```

3. Check HCP Vault cluster status in HCP Portal

#### Issue 4: "Warning: Deprecated Resource"

**Cause:** Using old `vault_kv_secret_v2` data source.

**Solution:**
This is just a warning. To eliminate it, update to the newer ephemeral resource in a future update:
```hcl
ephemeral "vault_kv_secret_v2" "oci" {
  mount = "oci"
  name  = "terraform"
}
```

#### Issue 5: Credentials Not Updating

**Cause:** Vault secrets updated but Terraform still using old values.

**Solution:**
1. The data source fetches secrets on every run
2. If cached somewhere, clear Terraform cache:
   ```bash
   rm -rf .terraform/
   terraform init
   ```

3. In HCP Terraform, discard any existing plans and start fresh

### Debug Mode

Enable detailed logging to troubleshoot issues:

```bash
# Local testing with debug logging
export TF_LOG=DEBUG
export VAULT_LOG_LEVEL=debug
terraform plan
```

In HCP Terraform, logs are automatically captured and available in the run details.

## Part 5: Security Best Practices

### 1. Principle of Least Privilege

- Grant only the minimum required Vault permissions
- Use workspace-specific JWT roles when possible
- Regularly audit Vault policies and access logs

### 2. Secret Rotation

Rotate OCI credentials periodically:

```bash
# Update credentials in Vault
vault kv put oci/terraform \
  tenancy_ocid="<new_value>" \
  user_ocid="<new_value>" \
  fingerprint="<new_value>" \
  private_key="<new_private_key>" \
  compartment_ocid="<value>" \
  region="<value>"

# No changes needed in Terraform - it will fetch new credentials on next run
```

### 3. Audit Logging

Enable and monitor Vault audit logs:

```bash
# In HCP Vault, audit logs are automatically enabled
# Review them regularly for unauthorized access attempts
```

### 4. Network Security

- Use HCP Vault's private networking when possible
- Implement IP allowlisting if needed
- Use VPC peering for enhanced security

### 5. Backup and Recovery

```bash
# Backup critical secrets
vault kv get -format=json oci/terraform > oci-backup.json.encrypted

# Encrypt the backup file
gpg -c oci-backup.json.encrypted

# Store securely (e.g., encrypted S
