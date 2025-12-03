# OCI Capacity Issue Solutions

## The Issue

```
Error: 500-InternalError, Out of host capacity
```

This error means Oracle Cloud Infrastructure doesn't have available compute capacity in your selected region/availability domain/shape combination.

## What We Changed

### Before (Likely to Hit Capacity Issues)
- **Availability Domain**: AD-1 (index 0)
- **OCPUs**: 4
- **Memory**: 24 GB
- **Region**: us-phoenix-1

### After (Better Capacity Availability)
- **Availability Domain**: AD-2 (index 1)
- **OCPUs**: 2
- **Memory**: 12 GB
- **Region**: us-phoenix-1

**Note:** Both configurations are within OCI's Always Free tier limits (up to 4 OCPUs and 24GB RAM total across all A1.Flex instances).

## Additional Solutions to Try

### 1. Try All Availability Domains

If AD-2 still doesn't work, try AD-3:

```hcl
availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
```

Or back to AD-1:
```hcl
availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
```

### 2. Try a Different Region

Some regions have better capacity. Add to your Vault secrets or update:

Popular regions with good capacity:
- `us-ashburn-1` (US East)
- `uk-london-1` (EU West)
- `ap-mumbai-1` (Asia)
- `ap-tokyo-1` (Asia)
- `eu-frankfurt-1` (EU Central)

### 3. Try a Different Shape

If A1.Flex (ARM) is consistently out of capacity, try x86:

```hcl
shape = "VM.Standard.E2.1.Micro"  # Free tier x86 option

# Remove shape_config block for micro instances
```

**Note:** E2.1.Micro is also free tier eligible but uses x86 architecture instead of ARM.

### 4. Reduce Resources Further

Try minimal resources:

```hcl
shape_config {
  ocpus         = 1
  memory_in_gbs = 6
}
```

### 5. Use Retry Logic

OCI capacity fluctuates. Sometimes waiting 15-30 minutes and trying again works.

### 6. Contact Oracle Support

Reference your OPC request ID when contacting support:
```
OPC request ID: b9943ca3f81c95b76d51ed0c62b41259
```

They can:
- Check real-time capacity
- Suggest alternative regions/ADs
- Potentially reserve capacity

## Best Practices for Free Tier

1. **Don't request maximum resources immediately**
   - Start with 1-2 OCPUs
   - Scale up once instance is created

2. **Be flexible with regions**
   - Home region isn't always best for capacity
   - Consider latency vs availability trade-off

3. **Try off-peak hours**
   - Early morning UTC often has better capacity
   - Weekend deployments sometimes easier

4. **Keep instances running**
   - Once created, capacity is reserved for you
   - Stopping/starting doesn't lose capacity
   - Terminating does lose capacity

## Quick Test: Check Available Shapes

You can query OCI to see what shapes have capacity:

```bash
oci compute shape list \
  --compartment-id <your-compartment-id> \
  --availability-domain <AD-name>
```

## Current Configuration Summary

Your updated `compute.tf` now uses:
- **Shape**: VM.Standard.A1.Flex (ARM)
- **Availability Domain**: AD-2 (index 1)
- **OCPUs**: 2
- **Memory**: 12 GB
- **Region**: us-phoenix-1

This configuration:
✅ Within Always Free tier limits
✅ Uses AD-2 (typically better availability than AD-1)
✅ Reduced resources for better capacity chances
✅ Still enough resources for most workloads

## Next Steps

1. Commit and push the changes
2. Trigger a new Terraform apply in HCP Terraform
3. If still failing, try AD-3 or a different region
4. Consider the alternative solutions above

Remember: **Vault authentication is working perfectly** - this is purely an OCI infrastructure capacity issue.
