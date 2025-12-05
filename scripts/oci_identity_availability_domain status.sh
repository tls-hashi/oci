#oci_identity_availability_domain status

#!/bin/bash
# check-oci-capacity.sh

REGIONS=(
  "us-ashburn-1"
  "us-phoenix-1"
  "ca-toronto-1"
  "ca-montreal-1"
  "us-sanjose-1"
  "uk-london-1"
  "eu-frankfurt-1"
  "ap-tokyo-1"
  "ap-mumbai-1"
  "ap-sydney-1"
)

SHAPE="VM.Standard.A1.Flex"
COMPARTMENT_ID="<YOUR_COMPARTMENT_ID>"  # Replace with actual compartment OCID from OCI Console

echo "Testing A1.Flex capacity across regions..."
echo "============================================"

for region in "${REGIONS[@]}"; do
  echo ""
  echo "Testing region: $region"
  
  # Try to list images as a proxy for availability
  oci compute image list \
    --compartment-id "$COMPARTMENT_ID" \
    --operating-system "Canonical Ubuntu" \
    --shape "$SHAPE" \
    --region "$region" \
    --lifecycle-state AVAILABLE \
    --limit 1 \
    2>/dev/null && echo "✓ Region $region is accessible" || echo "✗ Region $region failed"
done