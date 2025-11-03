#!/bin/bash
# Script to verify Vault JWT auth configuration for HCP Terraform
# Run this to diagnose any authentication issues

VAULT_ADDR="https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
VAULT_NAMESPACE="admin"

echo "======================================================================"
echo "Vault JWT Auth Verification for HCP Terraform"
echo "======================================================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check authentication
echo "Step 1: Verifying Vault authentication..."
if vault token lookup &>/dev/null; then
    echo -e "${GREEN}✓${NC} Authenticated to Vault"
    POLICIES=$(vault token lookup -format=json | jq -r '.data.policies | join(", ")')
    echo "  Current token policies: $POLICIES"
else
    echo -e "${RED}✗${NC} Not authenticated to Vault"
    echo "  Please authenticate first: vault login"
    exit 1
fi
echo ""

# Check if JWT auth is enabled
echo "Step 2: Checking JWT auth method..."
if vault auth list -format=json | jq -e '.["jwt/"]' &>/dev/null; then
    echo -e "${GREEN}✓${NC} JWT auth method is enabled"
    JWT_CONFIG=$(vault read -format=json auth/jwt/config 2>/dev/null)
    if [ $? -eq 0 ]; then
        ISSUER=$(echo "$JWT_CONFIG" | jq -r '.data.bound_issuer // "not set"')
        DISCOVERY_URL=$(echo "$JWT_CONFIG" | jq -r '.data.oidc_discovery_url // "not set"')
        echo "  Bound issuer: $ISSUER"
        echo "  OIDC discovery URL: $DISCOVERY_URL"
        
        if [ "$ISSUER" = "https://app.terraform.io" ]; then
            echo -e "${GREEN}✓${NC} Issuer correctly configured for HCP Terraform"
        else
            echo -e "${YELLOW}⚠${NC} Issuer should be https://app.terraform.io"
        fi
    fi
else
    echo -e "${RED}✗${NC} JWT auth method is NOT enabled"
    echo "  Run: vault auth enable jwt"
fi
echo ""

# Check if terraform-oci policy exists
echo "Step 3: Checking terraform-oci policy..."
if vault policy read terraform-oci &>/dev/null; then
    echo -e "${GREEN}✓${NC} Policy 'terraform-oci' exists"
    echo ""
    echo "Policy contents:"
    vault policy read terraform-oci | sed 's/^/  /'
else
    echo -e "${RED}✗${NC} Policy 'terraform-oci' does NOT exist"
    echo "  Run: vault policy write terraform-oci terraform-oci-policy.hcl"
fi
echo ""

# Check if JWT role exists
echo "Step 4: Checking JWT role 'terraform-oci'..."
if vault read auth/jwt/role/terraform-oci &>/dev/null; then
    echo -e "${GREEN}✓${NC} JWT role 'terraform-oci' exists"
    echo ""
    ROLE_DATA=$(vault read -format=json auth/jwt/role/terraform-oci)
    echo "Role configuration:"
    echo "  Role type: $(echo "$ROLE_DATA" | jq -r '.data.role_type')"
    echo "  Bound audiences: $(echo "$ROLE_DATA" | jq -r '.data.bound_audiences')"
    echo "  Bound claims: $(echo "$ROLE_DATA" | jq -r '.data.bound_claims')"
    echo "  User claim: $(echo "$ROLE_DATA" | jq -r '.data.user_claim')"
    echo "  Policies: $(echo "$ROLE_DATA" | jq -r '.data.policies')"
    echo "  TTL: $(echo "$ROLE_DATA" | jq -r '.data.ttl')"
    
    # Verify bound_claims pattern
    BOUND_CLAIMS=$(echo "$ROLE_DATA" | jq -r '.data.bound_claims.sub')
    if [[ "$BOUND_CLAIMS" == *"organization:tls-hashi"* ]] && [[ "$BOUND_CLAIMS" == *"workspace:OCI"* ]]; then
        echo -e "${GREEN}✓${NC} Bound claims correctly configured for OCI workspace"
    else
        echo -e "${YELLOW}⚠${NC} Bound claims may not match expected pattern"
        echo "  Expected pattern: organization:tls-hashi:project:*:workspace:OCI:run_phase:*"
    fi
else
    echo -e "${RED}✗${NC} JWT role 'terraform-oci' does NOT exist"
    echo "  Run setup-vault-jwt-auth.sh to create it"
fi
echo ""

# Check if OCI secrets exist
echo "Step 5: Checking OCI credentials in Vault..."
if vault kv get -mount=oci terraform &>/dev/null; then
    echo -e "${GREEN}✓${NC} OCI credentials found at oci/terraform"
    
    # Check for required fields
    SECRET_DATA=$(vault kv get -mount=oci -format=json terraform 2>/dev/null)
    if [ $? -eq 0 ]; then
        REQUIRED_FIELDS=("tenancy_ocid" "user_ocid" "fingerprint" "private_key" "compartment_ocid" "region")
        echo ""
        echo "Credential fields:"
        for field in "${REQUIRED_FIELDS[@]}"; do
            if echo "$SECRET_DATA" | jq -e ".data.data.$field" &>/dev/null; then
                VALUE=$(echo "$SECRET_DATA" | jq -r ".data.data.$field")
                # Show first 20 chars of value (except private_key)
                if [ "$field" = "private_key" ]; then
                    echo -e "  ${GREEN}✓${NC} $field: [present]"
                else
                    echo -e "  ${GREEN}✓${NC} $field: ${VALUE:0:20}..."
                fi
            else
                echo -e "  ${RED}✗${NC} $field: MISSING"
            fi
        done
    fi
else
    echo -e "${RED}✗${NC} OCI credentials NOT found at oci/terraform"
    echo "  Required path: oci/data/terraform (KV v2)"
    echo "  Required fields: tenancy_ocid, user_ocid, fingerprint, private_key, compartment_ocid, region"
fi
echo ""

# Test policy permissions
echo "Step 6: Testing policy permissions..."
if vault policy read terraform-oci &>/dev/null; then
    # Check if policy allows reading oci/data/terraform
    POLICY_CONTENT=$(vault policy read terraform-oci)
    if echo "$POLICY_CONTENT" | grep -q 'path "oci/data/terraform"'; then
        echo -e "${GREEN}✓${NC} Policy includes path 'oci/data/terraform'"
        if echo "$POLICY_CONTENT" | grep -A2 'path "oci/data/terraform"' | grep -q '"read"'; then
            echo -e "${GREEN}✓${NC} Policy allows 'read' capability"
        else
            echo -e "${RED}✗${NC} Policy missing 'read' capability"
        fi
    else
        echo -e "${RED}✗${NC} Policy does NOT include required path"
    fi
fi
echo ""

echo "======================================================================"
echo "Verification Summary"
echo "======================================================================"
echo ""
echo "If all checks pass, configure HCP Terraform workspace with:"
echo ""
echo "Environment Variables:"
echo "  TFC_VAULT_ADDR = $VAULT_ADDR"
echo "  TFC_VAULT_NAMESPACE = $VAULT_NAMESPACE"
echo "  TFC_VAULT_RUN_ROLE = terraform-oci"
echo ""
echo "Variable Set:"
echo "  Name: vault-dynamic-credentials"
echo "  vault_backed_dynamic_credentials = true"
echo ""
