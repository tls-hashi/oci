# Vault Credential Rotation Demo Guide

## Overview
This demo visually demonstrates HashiCorp Vault's credential rotation capabilities for customer presentations.

## What the Demo Shows

### 🎯 Key Concepts Demonstrated
1. **Current State** - View existing credentials in Vault
2. **Application Integration** - How apps consume credentials dynamically
3. **Rotation Process** - Update credentials in Vault
4. **Automatic Updates** - Apps get new credentials without changes
5. **Version History** - Full audit trail and rollback capability
6. **Zero Downtime** - No application restarts required

## Prerequisites

```bash
# 1. Authenticate to Vault
vault login

# 2. Set environment variables (if not already set)
export VAULT_ADDR="https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
```

## Running the Demo

### Full Interactive Demo
```bash
./demo-credential-rotation.sh
```

The script will:
- ✅ Use **colors and formatting** for visual appeal
- ✅ Pause at each step for explanation
- ✅ Show actual Vault commands and output
- ✅ Demonstrate the complete rotation lifecycle

### Demo Flow

```
Step 1: Verify Vault Authentication
  ↓
Step 2: View Current Credentials (Before Rotation)
  ↓
Step 3: Show How Applications Use These Credentials
  ↓
Step 4: Simulate Credential Rotation
  ↓
Step 5: Verify Credential Rotation
  ↓
Step 6: Applications Automatically Use New Credentials
  ↓
Step 7: Vault Version History & Rollback
  ↓
Step 8: Terraform Integration Demo
  ↓
Summary: Benefits & Next Steps
```

## Key Messages for Customers

### Security Benefits 🔒
- ✅ No credentials in code or configuration files
- ✅ Centralized credential management
- ✅ Complete audit trail of all changes
- ✅ Automated rotation reduces human error
- ✅ Instant rollback if issues occur

### Operational Benefits ⚡
- ✅ **Zero downtime** during rotation
- ✅ No application code changes needed
- ✅ No application restarts required
- ✅ Simplified compliance and auditing
- ✅ Faster incident response

### Developer Benefits 👨‍💻
- ✅ Same code works with rotated credentials
- ✅ Infrastructure as Code (Terraform) integration
- ✅ API-driven credential management
- ✅ Version control for credentials

## Real-World Credential Rotation Process

In production, the rotation process would be:

```bash
# 1. Generate new credentials in OCI
oci iam user api-key upload --user-id $USER_OCID --key-file new_key.pem

# 2. Update Vault with new credentials
vault kv put -mount=oci terraform \
    tenancy_ocid="ocid1.tenancy..." \
    user_ocid="ocid1.user..." \
    fingerprint="new:fp:..." \
    private_key=@new_private_key.pem \
    compartment_ocid="ocid1.compartment..." \
    region="us-ashburn-1"

# 3. Applications automatically pick up new credentials on next API call

# 4. After grace period, deactivate old credentials
oci iam user api-key delete --user-id $USER_OCID --fingerprint "old:fp:..."
```

## Customization

You can customize the demo by editing these variables in the script:

```bash
VAULT_ADDR="your-vault-address"
VAULT_NAMESPACE="your-namespace"
MOUNT_PATH="oci"
SECRET_PATH="terraform"
```

## Advanced Topics to Discuss

### 1. Automated Rotation
- Schedule rotation using Vault's database secrets engine
- Integrate with CI/CD for automated rotation
- Set up alerts for expiring credentials

### 2. Lease Management
- Dynamic secrets with automatic expiration
- Credential TTL policies
- Grace period handling

### 3. High Availability
- Vault cluster for production
- Replication across regions
- Disaster recovery scenarios

### 4. Compliance
- Audit logging for all credential access
- Meet regulatory requirements (SOC2, PCI-DSS)
- Automated compliance reporting

## Troubleshooting

### Not authenticated
```bash
vault login
```

### Can't read secrets
```bash
# Check your token permissions
vault token lookup

# Verify secret path exists
vault kv list -mount=oci
```

### Demo script permissions
```bash
chmod +x demo-credential-rotation.sh
```

## Additional Resources

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Terraform Vault Provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
- [OCI Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)

## Demo Tips 💡

1. **Run through once before presenting** to ensure everything works
2. **Explain each step** before pressing ENTER
3. **Highlight the "no code changes" aspect** - very powerful for customers
4. **Show the version history** - demonstrates audit capability
5. **Emphasize zero downtime** - critical for production systems

## Questions Customers Often Ask

### Q: What happens if Vault is down?
A: Applications can cache credentials, implement retry logic, or fail over to a Vault replica.

### Q: How often should we rotate credentials?
A: Industry best practice is every 90 days, but Vault enables more frequent rotation (daily/weekly) without operational burden.

### Q: Can this work with databases, cloud providers, etc.?
A: Yes! Vault supports rotation for databases (MySQL, PostgreSQL), cloud providers (AWS, Azure, GCP, OCI), and custom systems via API.

### Q: What's the migration path from hardcoded credentials?
A: Gradual migration - start with one application, prove the value, then expand across teams.

---

**Ready to run the demo?**
```bash
./demo-credential-rotation.sh
```
