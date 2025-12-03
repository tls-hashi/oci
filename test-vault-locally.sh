#!/bin/bash
# Script to test Vault connection locally
# This will help debug the setup before running in HCP Terraform

set -e

echo "======================================================================"
echo "Local Vault Connection Test"
echo "======================================================================"
echo ""

# Set Vault environment
export VAULT_ADDR="https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
export TF_LOG=DEBUG

echo "Step 1: Checking Vault authentication..."
if ! vault token lookup &>/dev/null; then
    echo "❌ Not authenticated to Vault"
    echo ""
    echo "Please run: vault login"
    exit 1
fi
echo "✓ Authenticated to Vault"
echo ""

echo "Step 2: Testing vault CLI access to OCI secrets..."
if vault kv get -mount=oci terraform &>/dev/null; then
    echo "✓ Can read OCI credentials via vault CLI"
    echo ""
    echo "Credential keys:"
    vault kv get -mount=oci -format=json terraform | jq -r '.data.data | keys[]'
else
    echo "❌ Cannot read OCI credentials"
    echo "Check that secrets exist at: oci/data/terraform"
    exit 1
fi
echo ""

echo "Step 3: Running terraform init..."
if terraform init; then
    echo "✓ Terraform init successful"
else
    echo "❌ Terraform init failed"
    exit 1
fi
echo ""

echo "Step 4: Running terraform plan with debug logging..."
echo "This will show detailed Vault provider behavior..."
echo ""
terraform plan -detailed-exitcode 2>&1 | tee /tmp/terraform-debug.log
PLAN_RESULT=$?

echo ""
echo "======================================================================"
echo "Test Complete"
echo "======================================================================"
echo ""

if [ $PLAN_RESULT -eq 0 ]; then
    echo "✓ Plan successful - no changes needed"
elif [ $PLAN_RESULT -eq 2 ]; then
    echo "✓ Plan successful - changes detected"
else
    echo "❌ Plan failed"
    echo ""
    echo "Debug log saved to: /tmp/terraform-debug.log"
    echo ""
    echo "Common issues:"
    echo "  1. Check if VAULT_TOKEN is set in environment"
    echo "  2. Verify token has correct permissions"
    echo "  3. Check if secrets path is correct: oci/data/terraform"
    exit 1
fi
