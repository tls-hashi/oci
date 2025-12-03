#!/bin/bash
# Load HCP credentials from Vault and run vault-radar scan

echo "🔐 Loading HCP credentials from Vault..."

# Get all required credentials from Vault
HCP_PROJECT_ID=$(vault kv get -field=project_id hcp/vault-radar 2>/dev/null)
HCP_CLIENT_ID=$(vault kv get -field=client_id hcp/vault-radar 2>/dev/null)
HCP_CLIENT_SECRET=$(vault kv get -field=client_secret hcp/vault-radar 2>/dev/null)

# Validate all credentials are present
if [ -z "$HCP_PROJECT_ID" ] || [ -z "$HCP_CLIENT_ID" ] || [ -z "$HCP_CLIENT_SECRET" ]; then
    echo "❌ Failed to retrieve HCP credentials from Vault"
    echo ""
    echo "Make sure you've stored all three values:"
    echo "  vault kv put hcp/vault-radar \\"
    echo "    project_id='<your-project-id>' \\"
    echo "    client_id='<service-principal-client-id>' \\"
    echo "    client_secret='<service-principal-client-secret>'"
    echo ""
    echo "Verify with:"
    echo "  vault kv get hcp/vault-radar"
    exit 1
fi

# Set environment variables
export HCP_PROJECT_ID
export HCP_CLIENT_ID
export HCP_CLIENT_SECRET

echo "✅ HCP credentials loaded from Vault"
echo "🔍 Running vault-radar scan..."
echo "Scanning: ${1:-.} (default: current directory)"
echo ""

# Run vault-radar
vault-radar scan folder \
    --path "${1:-.}" \
    --outfile /tmp/vault-radar-results.csv \
    --disable-ui

echo ""
echo "✅ Scan complete!"
echo "Results saved to: /tmp/vault-radar-results.csv"
echo ""
echo "View results:"
echo "  cat /tmp/vault-radar-results.csv"
echo ""
echo "View as JSON:"
echo "  vault-radar scan folder --path ${1:-.} --outfile /tmp/vault-radar-results.json --format json"
