#!/bin/bash
# Vault Credential Rotation Demo Script
# This script visually demonstrates how Vault handles credential rotation
# Perfect for customer demonstrations

set -e

# Colors for visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR="${VAULT_ADDR:-https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200}"
VAULT_NAMESPACE="${VAULT_NAMESPACE:-admin}"
MOUNT_PATH="oci"
SECRET_PATH="terraform"

export VAULT_ADDR VAULT_NAMESPACE

# Function to print section headers
print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to print step
print_step() {
    echo -e "${YELLOW}▶ Step $1:${NC} ${BOLD}$2${NC}"
    echo ""
}

# Function to pause for demo effect
pause_demo() {
    echo ""
    echo -e "${MAGENTA}[Press ENTER to continue]${NC}"
    read -r
}

# Function to show command being run
show_command() {
    echo -e "${GREEN}$ $1${NC}"
}

clear

print_header "🔐 HashiCorp Vault Credential Rotation Demo"

echo -e "${BOLD}This demo will show:${NC}"
echo "  1. Current credentials stored in Vault"
echo "  2. How applications consume these credentials"
echo "  3. Rotating credentials in Vault"
echo "  4. Applications automatically picking up new credentials"
echo "  5. No downtime or manual updates required"
echo ""

pause_demo

# ============================================================================
print_header "Step 1: Verify Vault Authentication"
# ============================================================================

print_step "1.1" "Checking authentication status"
show_command "vault token lookup"
if vault token lookup &>/dev/null; then
    echo -e "${GREEN}✓ Successfully authenticated to Vault${NC}"
    vault token lookup | grep -E "(display_name|policies|expire_time)" || true
else
    echo -e "${RED}❌ Not authenticated to Vault${NC}"
    echo ""
    echo "Please authenticate first:"
    echo "  vault login"
    exit 1
fi

pause_demo

# ============================================================================
print_header "Step 2: View Current Credentials (Before Rotation)"
# ============================================================================

print_step "2.1" "Reading current OCI credentials from Vault"
show_command "vault kv get -mount=$MOUNT_PATH $SECRET_PATH"

echo -e "${BOLD}Current credential metadata:${NC}"
vault kv get -mount=$MOUNT_PATH $SECRET_PATH | head -15

echo ""
echo -e "${BOLD}Available credential keys:${NC}"
vault kv get -mount=$MOUNT_PATH -format=json $SECRET_PATH | jq -r '.data.data | keys[]' | sed 's/^/  • /'

echo ""
echo -e "${BOLD}Current version:${NC}"
CURRENT_VERSION=$(vault kv get -mount=$MOUNT_PATH -format=json $SECRET_PATH | jq -r '.data.metadata.version')
echo -e "  Version: ${GREEN}$CURRENT_VERSION${NC}"

pause_demo

# ============================================================================
print_header "Step 3: Show How Applications Use These Credentials"
# ============================================================================

print_step "3.1" "Applications read credentials dynamically from Vault"

echo -e "${BOLD}Example: Terraform configuration${NC}"
echo ""
cat << 'EOF'
  data "vault_kv_secret_v2" "oci" {
    mount = "oci"
    name  = "terraform"
  }

  locals {
    tenancy_ocid = data.vault_kv_secret_v2.oci.data.tenancy_ocid
    user_ocid    = data.vault_kv_secret_v2.oci.data.user_ocid
    fingerprint  = data.vault_kv_secret_v2.oci.data.fingerprint
    private_key  = data.vault_kv_secret_v2.oci.data.private_key
  }
EOF

echo ""
echo -e "${GREEN}✓ No hardcoded credentials in code!${NC}"
echo -e "${GREEN}✓ Credentials are fetched at runtime${NC}"
echo -e "${GREEN}✓ When credentials rotate, apps get new values automatically${NC}"

pause_demo

# ============================================================================
print_header "Step 4: Simulate Credential Rotation"
# ============================================================================

print_step "4.1" "Creating backup of current credentials"

echo "In production, you would:"
echo "  1. Generate new credentials in OCI (new API key/user)"
echo "  2. Test the new credentials"
echo "  3. Update Vault with new credentials"
echo "  4. Deactivate old credentials after grace period"
echo ""
echo -e "${YELLOW}For this demo, we'll update a test field to show the rotation mechanism${NC}"

pause_demo

print_step "4.2" "Updating credentials in Vault"

# Get current data
echo "Fetching current secret data..."
CURRENT_DATA=$(vault kv get -mount=$MOUNT_PATH -format=json $SECRET_PATH | jq -r '.data.data')

# Add rotation metadata
ROTATION_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo ""
echo -e "${BOLD}Adding rotation metadata:${NC}"
echo "  • last_rotated: $ROTATION_TIME"
echo "  • rotation_demo: true"
echo ""

# Create updated secret (this simulates updating the actual credentials)
show_command "vault kv put -mount=$MOUNT_PATH $SECRET_PATH [credentials]"
echo ""

# In a real scenario, you'd update actual credential fields
# For demo, we'll just add metadata
vault kv patch -mount=$MOUNT_PATH $SECRET_PATH \
    last_rotated="$ROTATION_TIME" \
    rotation_demo="true" \
    demo_note="Credentials rotated during customer demo" > /dev/null

echo -e "${GREEN}✓ Credentials updated in Vault${NC}"

pause_demo

# ============================================================================
print_header "Step 5: Verify Credential Rotation"
# ============================================================================

print_step "5.1" "Checking new credential version"

vault kv get -mount=$MOUNT_PATH $SECRET_PATH | head -15

echo ""
NEW_VERSION=$(vault kv get -mount=$MOUNT_PATH -format=json $SECRET_PATH | jq -r '.data.metadata.version')
echo -e "${BOLD}Version comparison:${NC}"
echo -e "  Previous version: ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "  Current version:  ${GREEN}$NEW_VERSION${NC}"
echo ""

if [ "$NEW_VERSION" -gt "$CURRENT_VERSION" ]; then
    echo -e "${GREEN}✓ Credentials successfully rotated (version incremented)${NC}"
else
    echo -e "${RED}⚠ Version did not increment${NC}"
fi

pause_demo

print_step "5.2" "Viewing rotation metadata"

echo -e "${BOLD}Rotation details:${NC}"
vault kv get -mount=$MOUNT_PATH -format=json $SECRET_PATH | jq -r '.data.data | {last_rotated, rotation_demo, demo_note}'

pause_demo

# ============================================================================
print_header "Step 6: Applications Automatically Use New Credentials"
# ============================================================================

print_step "6.1" "How applications get updated credentials"

echo -e "${BOLD}Automatic credential refresh:${NC}"
echo ""
echo "  1️⃣  Application requests credentials from Vault"
echo "      └─> Vault returns LATEST version automatically"
echo ""
echo "  2️⃣  No application code changes needed"
echo "      └─> Same API call, new credentials"
echo ""
echo "  3️⃣  No application restart required"
echo "      └─> Next API call gets new credentials"
echo ""
echo -e "${GREEN}✓ Zero-downtime credential rotation!${NC}"

pause_demo

print_step "6.2" "Testing credential retrieval (simulating app request)"

show_command "vault kv get -mount=$MOUNT_PATH -format=json $SECRET_PATH"
echo ""

echo -e "${BOLD}Simulating application reading credentials:${NC}"
vault kv get -mount=$MOUNT_PATH -format=json $SECRET_PATH | jq -r '.data.data | {
  tenancy_ocid,
  user_ocid,
  fingerprint,
  region,
  last_rotated,
  rotation_demo
}'

echo ""
echo -e "${GREEN}✓ Application receives current credentials (version $NEW_VERSION)${NC}"

pause_demo

# ============================================================================
print_header "Step 7: Vault Version History & Rollback"
# ============================================================================

print_step "7.1" "Viewing credential history"

show_command "vault kv metadata get -mount=$MOUNT_PATH $SECRET_PATH"
echo ""

vault kv metadata get -mount=$MOUNT_PATH $SECRET_PATH | grep -A 20 "Versions:"

echo ""
echo -e "${BOLD}Key benefits:${NC}"
echo "  • Full audit trail of all credential changes"
echo "  • Can rollback to previous versions if needed"
echo "  • Tracks who changed what and when"

pause_demo

print_step "7.2" "Rollback capability (if needed)"

echo "If rotation caused issues, you can instantly rollback:"
echo ""
show_command "vault kv rollback -mount=$MOUNT_PATH -version=$CURRENT_VERSION $SECRET_PATH"
echo ""
echo -e "${YELLOW}(Not executing - just showing capability)${NC}"

pause_demo

# ============================================================================
print_header "Step 8: Terraform Integration Demo"
# ============================================================================

print_step "8.1" "Show Terraform automatically uses new credentials"

echo "When you run terraform plan/apply:"
echo ""
echo "  1. Terraform provider fetches credentials from Vault"
echo "  2. Gets the LATEST version automatically"
echo "  3. Uses new credentials without any config changes"
echo ""

if [ -f "vault.tf" ]; then
    echo -e "${BOLD}Your vault.tf configuration:${NC}"
    echo ""
    cat vault.tf | grep -A 5 "vault_kv_secret_v2" || cat vault.tf | head -20
    echo ""
fi

echo -e "${GREEN}✓ Infrastructure code never needs updating for credential rotation${NC}"

pause_demo

# ============================================================================
print_header "📊 Demo Summary: Benefits of Vault Credential Rotation"
# ============================================================================

echo -e "${BOLD}What we demonstrated:${NC}"
echo ""
echo -e "${GREEN}✓${NC} Centralized credential storage in Vault"
echo -e "${GREEN}✓${NC} Applications consume credentials dynamically"
echo -e "${GREEN}✓${NC} Credentials rotated in one place (Vault)"
echo -e "${GREEN}✓${NC} Applications automatically receive new credentials"
echo -e "${GREEN}✓${NC} No code changes or application restarts needed"
echo -e "${GREEN}✓${NC} Full audit trail and version history"
echo -e "${GREEN}✓${NC} Instant rollback capability"
echo -e "${GREEN}✓${NC} Zero downtime during rotation"
echo ""

echo -e "${BOLD}${BLUE}Security Benefits:${NC}"
echo "  🔒 Reduced credential exposure"
echo "  🔒 Automated rotation reduces human error"
echo "  🔒 Complete audit trail of all changes"
echo "  🔒 No credentials in code or config files"
echo "  🔒 Centralized access control and policies"
echo ""

echo -e "${BOLD}${MAGENTA}Operational Benefits:${NC}"
echo "  ⚡ Faster incident response"
echo "  ⚡ Simplified credential management"
echo "  ⚡ Reduced operational overhead"
echo "  ⚡ Easy compliance and auditing"
echo "  ⚡ No application downtime"
echo ""

print_header "✅ Demo Complete!"

echo -e "${BOLD}Next Steps:${NC}"
echo "  • Review Vault audit logs: vault audit list"
echo "  • Set up automated rotation policies"
echo "  • Integrate with your CI/CD pipeline"
echo "  • Configure alerts for credential expiration"
echo ""
echo -e "${CYAN}Thank you for watching the Vault credential rotation demo!${NC}"
echo ""
