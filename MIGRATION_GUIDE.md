# Migration Guide: Community Edition → HCP Terraform

This guide helps you migrate from the existing Terraform Community Edition setup to HCP Terraform with HashiCorp Boundary integration.

## Overview of Changes

### What's Changed

✅ **Removed:**
- All SSH configuration (keys, security rules, provisioners)
- SSH bastion setup
- Google Cloud Platform resources (GCP provider, compute instances)
- File-based provisioning
- Local file references (e.g., `file()` function for SSH keys)

✅ **Added:**
- HCP Terraform (Terraform Cloud) integration
- Dynamic DNS record management
- Resource tagging strategy
- Variable validation
- Comprehensive documentation
- Cost estimation capabilities
- Remote state management

✅ **Updated:**
- OCI provider authentication (now uses key content, not file paths)
- Network security groups (removed SSH port 22)
- Module variables (removed SSH-related parameters)
- Instance configurations (removed SSH metadata and provisioners)
- Naming conventions (now use variables for consistency)

### Why These Changes?

1. **HCP Terraform**: Provides enterprise-grade state management, collaboration, and CI/CD
2. **Remove SSH**: Modern zero-trust approach using HashiCorp Boundary for access
3. **Dynamic Configuration**: Makes infrastructure more maintainable and portable
4. **Better Security**: Credentials in HCP Terraform workspace, not in files

## Pre-Migration Checklist

- [ ] Back up current Terraform state file
- [ ] Document current infrastructure (IPs, resource IDs)
- [ ] Export current Terraform outputs
- [ ] Create HCP Terraform account
- [ ] Prepare OCI credentials
- [ ] Review all TODO items in updated code

## Migration Steps

### Phase 1: Backup Current State

```bash
# Export current state
terraform state pull > terraform.tfstate.backup

# Export outputs
terraform output -json > outputs.backup.json

# List all resources
terraform state list > resources.backup.txt
```

### Phase 2: Set Up HCP Terraform

Follow the detailed steps in `HCP_TERRAFORM_SETUP.md`:

1. Create HCP Terraform organization
2. Create workspace
3. Configure variables (all OCI credentials)
4. Update `main.tf` with your organization name

### Phase 3: Migrate State

#### Option A: Import Existing Infrastructure (Recommended)

This approach re-imports existing resources under HCP Terraform management:

1. Update your code to HCP Terraform configuration
2. Initialize with HCP Terraform:
   ```bash
   terraform login
   terraform init
   ```

3. Import existing resources:
   ```bash
   # Example for VCN
   terraform import oci_core_virtual_network.default_vcn <vcn-ocid>
   
   # Repeat for all resources
   terraform import oci_core_subnet.public_subnet <subnet-ocid>
   terraform import oci_core_subnet.private_subnet <subnet-ocid>
   terraform import oci_core_instance.reverse_proxy <instance-ocid>
   # ... etc
   ```

4. Verify with plan:
   ```bash
   terraform plan
   ```

5. If plan shows no changes, you're successfully migrated!

#### Option B: Migrate State File Directly

This approach moves your existing state to HCP Terraform:

1. Ensure local state is up-to-date:
   ```bash
   terraform plan  # Should show no changes
   ```

2. Update `main.tf` with HCP Terraform cloud block

3. Run migration:
   ```bash
   terraform init
   # Terraform will prompt to migrate state
   # Answer 'yes' when prompted
   ```

4. Verify migration:
   ```bash
   terraform plan  # Should connect to HCP Terraform
   ```

**Note**: This option requires careful handling and may not work if you've made breaking changes to resource configurations.

### Phase 4: Update Resources (Breaking Changes)

Some changes are breaking and require careful handling:

#### 1. Remove SSH Access

**Impact**: No more SSH access until Boundary is configured

**Action Required**:
```bash
# Remove SSH security group rules
# This is already done in the new code
terraform plan  # Review changes
```

**Workaround**: If you need temporary SSH access during migration:
- Keep old SSH NSG rules until Boundary is ready
- Use OCI Bastion service as temporary solution
- Or manually add SSH rules temporarily

#### 2. Update Instance Metadata

**Impact**: Instances need to be restarted or recreated

**Current instances**: Have SSH keys in metadata
**New instances**: No SSH keys in metadata

**Action Required**:
```bash
# Check what will change
terraform plan

# If instances show replacement, consider:
# 1. Accepting the replacement (downtime)
# 2. Using lifecycle.ignore_changes temporarily
# 3. Migrating workloads first
```

#### 3. Remove GCP Resources

**Impact**: GCP resources in management module will be destroyed

**Action Required**:
```bash
# If you have actual GCP resources, remove them separately:
terraform state rm google_compute_instance.reverse_proxy
terraform state rm google_compute_network.vpc
# etc.

# Or just remove them from code and let Terraform destroy them
```

### Phase 5: Verify Migration

1. Check HCP Terraform workspace shows correct state
2. Verify all resources are managed:
   ```bash
   terraform state list
   ```

3. Compare with pre-migration backup:
   ```bash
   diff <(cat resources.backup.txt | sort) <(terraform state list | sort)
   ```

4. Test DNS resolution:
   ```bash
   dig 2two2.me
   dig media.2two2.me
   dig git.2two2.me
   ```

5. Verify instances are running in OCI Console

### Phase 6: Clean Up

1. Remove old SSH keys from instances (if needed)
2. Delete local state files (after confirming HCP Terraform works):
   ```bash
   # DO NOT delete until absolutely sure!
   # rm terraform.tfstate
   # rm terraform.tfstate.backup
   ```

3. Update `.gitignore` if needed

4. Remove deprecated scripts:
   ```bash
   # These are now deprecated
   # update_hosts_and_alias.sh
   ```

## Post-Migration Tasks

### Immediate Tasks

- [ ] Verify all infrastructure is working
- [ ] Test DNS records
- [ ] Confirm instances accessible (via OCI Console for now)
- [ ] Set up HCP Terraform notifications
- [ ] Enable cost estimation
- [ ] Configure team access in HCP Terraform

### Short-Term Tasks

- [ ] Set up HashiCorp Boundary for access
- [ ] Implement Sentinel policies
- [ ] Configure VCS-driven workflow (if CLI-driven)
- [ ] Set up monitoring/alerting
- [ ] Document runbooks
- [ ] Train team on HCP Terraform

### Long-Term Tasks

- [ ] Implement multi-environment setup (dev/staging/prod)
- [ ] Create disaster recovery procedures
- [ ] Set up automated testing
- [ ] Optimize costs based on estimation data
- [ ] Regular security audits

## Rollback Plan

If migration fails:

1. **Immediate Rollback**:
   ```bash
   # Use terraform login with different credentials
   # Or disable cloud block temporarily
   
   # Restore from backup
   cp terraform.tfstate.backup terraform.tfstate
   terraform init -reconfigure  # Use local backend
   terraform plan  # Verify state is correct
   ```

2. **Partial Rollback**:
   - Keep HCP Terraform but restore old SSH configuration
   - Re-add SSH security group rules manually
   - Update instance metadata to include SSH keys

3. **Full Rollback**:
   ```bash
   # Switch back to old repository version
   git checkout <previous-commit>
   
   # Restore state
   cp terraform.tfstate.backup terraform.tfstate
   
   # Re-init with local backend
   terraform init -reconfigure
   ```

## Troubleshooting

### State Mismatch Errors

**Problem**: "Resource X doesn't match state"
- **Solution**: Review what changed in configuration
- **Solution**: Use `terraform import` to re-import
- **Solution**: Check for resource ID changes

### Authentication Errors

**Problem**: "Failed to authenticate with OCI"
- **Solution**: Verify HCP Terraform workspace variables
- **Solution**: Ensure private key has proper format
- **Solution**: Check all OCIDs are correct

### Resource Conflicts

**Problem**: "Resource already exists"
- **Solution**: Import existing resource
- **Solution**: Remove from state and re-import
- **Solution**: Check for duplicate resources

### DNS Issues

**Problem**: DNS not resolving
- **Solution**: Verify zone name matches
- **Solution**: Check name servers are correct
- **Solution**: Allow time for propagation (up to 24h)

## Known Issues & Limitations

1. **No SSH Access**: Until Boundary is configured, use OCI Console for instance access
2. **Hardcoded IPs**: Media and git subdomains still have hardcoded IPs (TODO items)
3. **Instance Recreation**: Some instances may need to be recreated due to metadata changes
4. **State Migration**: May require manual import of resources

## Getting Help

- **HCP Terraform Support**: https://support.hashicorp.com
- **OCI Support**: https://cloud.oracle.com/support
- **Community**: https://discuss.hashicorp.com
- **Documentation**: See README.md and HCP_TERRAFORM_SETUP.md

## Summary

**Time Estimate**: 2-4 hours (depending on resource count and complexity)

**Risk Level**: Medium (with proper backups and testing)

**Recommended Approach**:
1. Test in non-production environment first
2. Keep backups until confident
3. Migrate during low-traffic period
4. Have rollback plan ready

**Benefits After Migration**:
- Professional state management
- Team collaboration features
- Cost estimation
- Better security (no SSH)
- Automated CI/CD (with VCS workflow)
- Audit trail
- Version control integration

---

**Last Updated**: October 2025
**Migration Version**: 1.0 (Community → HCP Terraform + Boundary prep)
