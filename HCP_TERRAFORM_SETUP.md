# HCP Terraform Quick Setup Guide

This guide walks you through setting up HCP Terraform (Terraform Cloud) for this OCI infrastructure project.

## Step 1: Create HCP Terraform Account

1. Go to https://app.terraform.io
2. Sign up or log in
3. Create a new organization (or use existing)

## Step 2: Create Workspace

### Option A: VCS-Driven Workflow (Recommended)

1. Click "New Workspace"
2. Select "Version control workflow"
3. Connect to your GitHub repository:
   - Authorize HCP Terraform to access GitHub
   - Select this repository
4. Configure workspace:
   - **Name**: `oci-infrastructure`
   - **Terraform Working Directory**: Leave blank (root directory)
   - **VCS Branch**: `main`
5. Click "Create workspace"

### Option B: CLI-Driven Workflow

1. Click "New Workspace"
2. Select "CLI-driven workflow"
3. Configure workspace:
   - **Name**: `oci-infrastructure`
4. Click "Create workspace"

## Step 3: Configure Workspace Settings

1. Navigate to workspace Settings > General
2. Configure:
   - **Terraform Version**: Select latest 1.5.x or newer
   - **Execution Mode**: Remote
   - **Apply Method**: Manual apply (recommended for production)
3. Save settings

## Step 4: Set Up Variables

### Navigate to Variables

1. In your workspace, click "Variables"
2. Add the following variables:

### Required Sensitive Variables

Click "Add variable" and set **Category: Terraform variable**, **Sensitive: Yes**

| Key | Value | Sensitive | HCL |
|-----|-------|-----------|-----|
| `tenancy_ocid` | Your OCI tenancy OCID | ✓ | ✗ |
| `user_ocid` | Your OCI user OCID | ✓ | ✗ |
| `fingerprint` | Your OCI API key fingerprint | ✓ | ✗ |
| `private_key` | Full OCI API private key content | ✓ | ✗ |

**Finding OCI values:**
- Tenancy OCID: OCI Console > Identity > Tenancy Information
- User OCID: OCI Console > Identity > Users > Your User
- Fingerprint: OCI Console > Identity > Users > Your User > API Keys
- Private Key: Content of your `.pem` file (include BEGIN/END lines)

### Required Non-Sensitive Variables

Click "Add variable" and set **Category: Terraform variable**, **Sensitive: No**

| Key | Value | Sensitive | HCL |
|-----|-------|-----------|-----|
| `compartment_ocid` | Your OCI compartment OCID | ✗ | ✗ |
| `region` | e.g., `us-phoenix-1` | ✗ | ✗ |

### Optional Variables

Add these if you want to override defaults:

| Key | Default | Description |
|-----|---------|-------------|
| `naming_prefix` | `twotwotwo` | Resource name prefix |
| `environment` | `prod` | Environment label |
| `dns_zone_name` | `2two2.me` | DNS zone name |
| `vcn_cidr` | `10.0.0.0/16` | VCN CIDR block |
| `public_subnet_cidr` | `10.0.1.0/24` | Public subnet CIDR |
| `private_subnet_cidr` | `10.0.2.0/24` | Private subnet CIDR |

## Step 5: Update main.tf

1. Edit `main.tf` in your repository
2. Find the `cloud` block:
   ```hcl
   terraform {
     cloud {
       organization = "YOUR_ORG_NAME"  # Update this
       workspaces {
         name = "oci-infrastructure"    # Your workspace name
       }
     }
   }
   ```
3. Replace `YOUR_ORG_NAME` with your HCP Terraform organization name
4. Update workspace name if different
5. Commit and push

## Step 6: Connect and Initialize

### For VCS-Driven Workflow:

Push your changes to GitHub main branch:
```bash
git add .
git commit -m "Configure HCP Terraform"
git push origin main
```

HCP Terraform will automatically:
- Detect the push
- Run `terraform plan`
- Wait for your approval to apply

### For CLI-Driven Workflow:

Authenticate with HCP Terraform:
```bash
# Login to HCP Terraform
terraform login

# Initialize
terraform init

# Plan
terraform plan

# Apply (if plan looks good)
terraform apply
```

## Step 7: Review and Apply

1. Go to your workspace in HCP Terraform UI
2. Review the plan output
3. Check cost estimation (if enabled)
4. Click "Confirm & Apply" if everything looks correct
5. Monitor the apply progress

## Step 8: Enable Additional Features (Optional)

### Cost Estimation

1. Workspace Settings > Cost Estimation
2. Enable cost estimation
3. Set monthly budget threshold (optional)

### Notifications

1. Workspace Settings > Notifications
2. Add notification destination:
   - Slack webhook
   - Email
   - Generic webhook
3. Configure which events trigger notifications

### Run Triggers

If you have dependent workspaces:
1. Workspace Settings > Run Triggers
2. Connect source workspaces
3. Auto-trigger runs on upstream changes

### Sentinel Policies (Paid tier)

1. Organization Settings > Policy Sets
2. Create new policy set
3. Connect to VCS or upload policies
4. Enforce governance rules

## Verification

After successful apply:

1. Check Outputs in HCP Terraform UI
2. Verify infrastructure in OCI Console
3. Test DNS resolution (if applicable)
4. Confirm instances are running

## Next Steps

- [ ] Review security group rules
- [ ] Configure monitoring/alerting
- [ ] Set up HashiCorp Boundary for access
- [ ] Implement CI/CD pipeline
- [ ] Add Sentinel policies
- [ ] Document runbooks

## Troubleshooting

### Authentication Errors

**Problem**: "Error: authentication failed"
- **Solution**: Verify all OCI credentials in workspace variables
- **Solution**: Ensure private key includes BEGIN/END lines
- **Solution**: Check fingerprint matches API key

### Workspace Not Found

**Problem**: "Error: No workspaces found"
- **Solution**: Verify organization name in `main.tf`
- **Solution**: Run `terraform login` to authenticate
- **Solution**: Check workspace exists in HCP Terraform UI

### Variables Not Set

**Problem**: "var.X is required"
- **Solution**: Add missing variables in workspace settings
- **Solution**: Mark sensitive variables as sensitive
- **Solution**: Verify variable names match exactly

### State Lock

**Problem**: "Error acquiring the state lock"
- **Solution**: Wait for current run to complete
- **Solution**: Cancel stuck run in HCP Terraform UI
- **Solution**: Force unlock (caution: only if necessary)

## Support Resources

- **HCP Terraform Docs**: https://developer.hashicorp.com/terraform/cloud-docs
- **OCI Provider Docs**: https://registry.terraform.io/providers/oracle/oci/latest/docs
- **Community Forum**: https://discuss.hashicorp.com/c/terraform-core

---

**Setup Time**: ~15-30 minutes
**Prerequisites**: OCI account, GitHub account, HCP Terraform account
