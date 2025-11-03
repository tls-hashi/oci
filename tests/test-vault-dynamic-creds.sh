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
if echo "$PRIVATE_KEY" | grep -qE "BEGIN (RSA )?PRIVATE KEY"; then
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
