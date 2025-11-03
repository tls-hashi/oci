#!/bin/bash
# Script to configure Vault JWT auth for HCP Terraform dynamic credentials
# Run this against your HCP Vault KV cluster

set -e

VAULT_ADDR="https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
VAULT_NAMESPACE="admin"

echo "======================================================================"
echo "Setting up Vault JWT Auth for HCP Terraform"
echo "======================================================================"
echo ""
echo "Vault Address: $VAULT_ADDR"
echo "Namespace: $VAULT_NAMESPACE"
echo ""

# Check if we're authenticated
echo "Step 1: Verifying authentication..."
if ! vault token lookup &>/dev/null; then
    echo "❌ ERROR: Not authenticated to Vault"
    echo "Please set VAULT_TOKEN or run 'vault login' first"
    exit 1
fi
echo "✓ Authenticated to Vault"
echo ""

# Enable JWT auth method if not already enabled
echo "Step 2: Enabling JWT auth method..."
if vault auth list | grep -q "jwt/"; then
    echo "✓ JWT auth already enabled"
else
    vault auth enable jwt
    echo "✓ JWT auth enabled"
fi
echo ""

# Configure JWT auth method for HCP Terraform
echo "Step 3: Configuring JWT auth method..."
vault write auth/jwt/config \
    oidc_discovery_url="https://app.terraform.io" \
    bound_issuer="https://app.terraform.io"
echo "✓ JWT auth configured"
echo ""

# Create the policy
echo "Step 4: Creating terraform-oci policy..."
vault policy write terraform-oci terraform-oci-policy.hcl
echo "✓ Policy created"
echo ""

# Create the JWT role
echo "Step 5: Creating JWT role for OCI workspace..."
vault write auth/jwt/role/terraform-oci @jwt-role.json
echo "✓ JWT role created"
echo ""

# Verify the setup
echo "Step 6: Verifying setup..."
echo ""
echo "Policy details:"
vault policy read terraform-oci
echo ""
echo "JWT role details:"
vault read auth/jwt/role/terraform-oci
echo ""

echo "======================================================================"
echo "Setup Complete!"
echo "======================================================================"
echo ""
echo "Next steps:"
echo "1. Configure HCP Terraform workspace with dynamic credentials:"
echo "   - Variable Set: vault_backed_dynamic_credentials = true"
echo "   - TFC_VAULT_ADDR = $VAULT_ADDR"
echo "   - TFC_VAULT_NAMESPACE = $VAULT_NAMESPACE"
echo "   - TFC_VAULT_RUN_ROLE = terraform-oci"
echo ""
echo "2. Ensure the OCI credentials are stored in Vault at:"
echo "   Path: oci/data/terraform"
echo "   Required keys: tenancy_ocid, user_ocid, fingerprint, private_key,"
echo "                  compartment_ocid, region"
echo ""
