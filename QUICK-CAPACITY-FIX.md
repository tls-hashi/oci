# Quick Fix for OCI Capacity Errors

## Current Configuration
- **Availability Domain**: AD-3 (index 2)
- **Shape**: VM.Standard.A1.Flex (ARM)
- **Resources**: 1 OCPU, 6GB RAM

## If Still Getting Capacity Errors

### Option 1: Try Each Availability Domain
Edit `compute.tf` line 41, change the index:

```hcl
# Try AD-1 (index 0)
availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

# Try AD-2 (index 1)
availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name

# Try AD-3 (index 2) - CURRENT
availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
```

### Option 2: Switch to x86 Free Tier Shape (E2.1.Micro)

**IMPORTANT:** E2.1.Micro can ONLY be created in AD-3 (emiq:PHX-AD-3)

The easiest way:

```bash
# Backup current config
mv compute.tf compute-a1-flex.tf.backup

# Use the x86 config
cp compute-e2-micro.tf.example compute.tf

# Commit and push
git add compute.tf
git commit -m "Switch to E2.1.Micro x86 shape (AD-3 only)"
git push
```

This automatically uses the correct AD-3 and configures everything for E2.1.Micro.

### Option 3: Try Different Region
This requires updating your Vault secrets with a new region:

1. Check regions with good capacity:
   - `us-ashburn-1` (US East - usually good)
   - `uk-london-1` (Europe)
   - `ap-tokyo-1` (Asia)

2. Update in Vault:
```bash
vault kv patch -mount=oci terraform region=us-ashburn-1
```

### Option 4: Wait and Retry
Capacity is dynamic. Try:
- Different time of day (early UTC morning often better)
- Weekends
- Wait 15-30 minutes between attempts

## Quick Commands

```bash
# Commit current change (AD-3)
git add compute.tf
git commit -m "Try AD-3 for better capacity"
git push

# After pushing, trigger new run in HCP Terraform
```

## If Nothing Works
Consider opening an Oracle support ticket with your OPC request ID. They can check capacity or potentially reserve resources for you.
