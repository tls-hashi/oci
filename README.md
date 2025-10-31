# OCI Infrastructure - HCP Terraform Managed

Modern Oracle Cloud Infrastructure (OCI) deployment managed via HCP Terraform (Terraform Cloud), with access control via HashiCorp Boundary (future implementation).

## Architecture Overview

This infrastructure deploys a secure, scalable environment on Oracle Cloud Infrastructure:

- **VCN (Virtual Cloud Network)**: Isolated network with public and private subnets
- **Reverse Proxy Instance**: Oracle Linux instance in public subnet handling HTTP/HTTPS traffic
- **Management Instance**: Ubuntu instance in private subnet for internal workloads
- **DNS Management**: Automated DNS record management via OCI DNS
- **Access Control**: HashiCorp Boundary integration (planned) - SSH access removed

### Network Topology

```
Internet
    |
    v
[Internet Gateway]
    |
    v
[Public Subnet] ---- [Reverse Proxy (Oracle Linux)]
    |                     |
    |                     | (dual-homed)
    |                     v
[Private Subnet] ---- [Private VNIC]
    |
    v
[Management Instance (Ubuntu)]
    |
    v
[NAT Gateway] --> Internet (outbound only)
```

## Prerequisites

### Required Accounts & Tools

1. **HCP Terraform Account**: Sign up at https://app.terraform.io
2. **OCI Account**: Oracle Cloud Infrastructure account
3. **Terraform CLI**: v1.5.0 or later (for local development/testing)
4. **Git**: For version control

### OCI Setup

1. Create or identify your OCI compartment
2. Generate OCI API key pair:
   - Navigate to: Identity > Users > Your User > API Keys
   - Click "Add API Key"
   - Download private key (keep secure!)
   - Note the fingerprint

## HCP Terraform Setup

### 1. Create Organization (if needed)

1. Log in to https://app.terraform.io
2. Create a new organization or select existing
3. Note your organization name

### 2. Create Workspace

1. In HCP Terraform, click "New Workspace"
2. Choose workflow type:
   - **VCS-driven** (recommended): Connects to GitHub for automatic runs
   - **CLI-driven**: Manual terraform commands
3. Name: `oci-infrastructure` (or your preference)
4. Configure workspace settings:
   - Terraform Version: >= 1.5.0
   - Execution Mode: Remote
   - Apply Method: Manual (recommended) or Auto

### 3. Configure Variables

In your HCP Terraform workspace, add these variables:

#### Terraform Variables (Set as Sensitive)

| Variable | Type | Sensitive | Description |
|----------|------|-----------|-------------|
| `tenancy_ocid` | terraform | ✓ | OCI Tenancy OCID |
| `user_ocid` | terraform | ✓ | OCI User OCID |
| `fingerprint` | terraform | ✓ | OCI API Key Fingerprint |
| `private_key` | terraform | ✓ | OCI API Private Key (full content) |
| `compartment_ocid` | terraform | ✗ | OCI Compartment OCID |
| `region` | terraform | ✗ | OCI Region (e.g., us-phoenix-1) |

#### Optional Terraform Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `naming_prefix` | terraform | `twotwotwo` | Prefix for resource names |
| `environment` | terraform | `prod` | Environment name |
| `dns_zone_name` | terraform | `2two2.me` | DNS zone name |
| `vcn_cidr` | terraform | `10.0.0.0/16` | VCN CIDR block |
| `public_subnet_cidr` | terraform | `10.0.1.0/24` | Public subnet CIDR |
| `private_subnet_cidr` | terraform | `10.0.2.0/24` | Private subnet CIDR |

**IMPORTANT**: Mark `tenancy_ocid`, `user_ocid`, `fingerprint`, and `private_key` as **sensitive** in HCP Terraform!

### 4. Update Configuration Files

1. Update `main.tf`:
   ```hcl
   cloud {
     organization = "YOUR_ORG_NAME"  # Replace with your organization
     workspaces {
       name = "oci-infrastructure"    # Your workspace name
     }
   }
   ```

2. Commit and push to trigger a run (if VCS-driven)

## Local Development Setup

For local testing before committing:

### 1. Install Terraform CLI

```bash
# macOS
brew install terraform

# Verify installation
terraform version
```

### 2. Login to HCP Terraform

```bash
terraform login
```

Follow prompts to authenticate. This creates `~/.terraform.d/credentials.tfrc.json`

### 3. Initialize Terraform

```bash
terraform init
```

This connects to your HCP Terraform workspace.

### 4. Local Plan/Apply

```bash
# Create execution plan
terraform plan

# Apply changes (requires workspace permission)
terraform apply
```

**Note**: In HCP Terraform mode, state is always remote. Local commands still execute remotely.

## Deployment

### VCS-Driven Workflow (Recommended)

1. Make changes to `.tf` files
2. Commit and push to repository
3. HCP Terraform automatically triggers:
   - Terraform plan on pull requests
   - Shows plan results in PR comments
   - Terraform apply on merge to main branch
4. Review and approve runs in HCP Terraform UI

### CLI-Driven Workflow

1. Make changes locally
2. Run `terraform plan` to preview
3. Run `terraform apply` to deploy
4. Confirm in HCP Terraform UI

## Infrastructure Components

### Compute Instances

- **Reverse Proxy**: Oracle Linux 8, VM.Standard.E2.1.Micro (1 OCPU, 2GB RAM)
- **Management**: Ubuntu 24.04, VM.Standard.A1.Flex (3 OCPUs, 22GB RAM)

### Network Security

- **HTTP (80)**: Open to internet for web traffic
- **HTTPS (443)**: Open to internet for secure web traffic
- **Port 3000**: Internal only (10.0.0.0/16)
- **Port 9000**: Webhook notifications (consider restricting)
- **SSH (22)**: REMOVED - Boundary will provide secure access

### DNS Configuration

DNS records automatically configured using Terraform outputs:
- Root domain points to reverse proxy public IP
- Subdomains require manual IP updates (see TODO comments in dns.tf)

## Access Management

### Current State

SSH access has been removed from all security groups and instance configurations in preparation for HashiCorp Boundary integration.

### Future: HashiCorp Boundary Integration

Planned implementation will provide:
- Identity-based access control
- Just-in-time session access
- Session recording and auditing
- No exposed SSH ports
- Centralized access management

**To access instances**: Boundary configuration required (see future documentation)

## Cost Estimation

HCP Terraform provides automatic cost estimation for each run:
- View estimated costs before applying
- Configure cost thresholds and alerts
- Track spending trends over time

## Outputs

After successful deployment, access these outputs:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output reverse_proxy_ip
terraform output mgmt_private_ip
```

## Maintenance

### Updating Infrastructure

1. Modify `.tf` files as needed
2. Commit changes (VCS-driven) or run `terraform plan` (CLI-driven)
3. Review plan in HCP Terraform UI
4. Approve and apply changes

### State Management

State is automatically managed by HCP Terraform:
- Encrypted at rest
- Versioned (rollback supported)
- Locked during operations
- Backed up automatically

### Upgrading Terraform Version

1. In HCP Terraform workspace settings
2. Navigate to "General Settings"
3. Update Terraform version
4. Test with plan before applying

## Security Best Practices

### DO

✅ Store credentials in HCP Terraform as sensitive variables
✅ Mark private keys and OCIDs as sensitive
✅ Use VCS-driven workflow for audit trail
✅ Enable cost estimation and monitoring
✅ Review all plans before applying
✅ Use Boundary for access (when implemented)
✅ Enable policy as code (Sentinel) for governance

### DON'T

❌ Commit `terraform.tfvars` with real values
❌ Store credentials in version control
❌ Share API keys or private keys
❌ Bypass plan review in production
❌ Use SSH for access (Boundary preferred)
❌ Ignore cost estimates

## Troubleshooting

### Common Issues

**Issue**: "No declaration found for var.X"
- **Solution**: Ensure all variables are set in HCP Terraform workspace

**Issue**: Authentication failures
- **Solution**: Verify OCI credentials in workspace variables
- **Solution**: Check private key format (should include full content with headers)

**Issue**: "Workspace not found"
- **Solution**: Update organization/workspace name in `main.tf`
- **Solution**: Run `terraform login` for CLI access

**Issue**: State lock errors
- **Solution**: Wait for current operation to complete
- **Solution**: Force unlock in HCP Terraform UI (use cautiously)

### Getting Help

- HCP Terraform Docs: https://developer.hashicorp.com/terraform/cloud-docs
- OCI Provider Docs: https://registry.terraform.io/providers/oracle/oci/latest/docs
- Report issues: Use GitHub Issues in this repository

## Project Structure

```
.
├── main.tf                          # Root configuration & HCP Terraform setup
├── variables.tf                     # Variable definitions
├── network.tf                       # VCN, subnets, gateways, route tables
├── dns.tf                          # DNS zone and records
├── outputs.tf                      # Output definitions
├── versions.tf                     # Version constraints (legacy, merged to main.tf)
├── terraform.tfvars.example        # Example variable values
├── .gitignore                      # Git ignore rules
└── modules/
    ├── reverse_proxy/
    │   ├── main.tf                # Reverse proxy instance
    │   ├── variables.tf           # Module variables
    │   ├── outputs.tf            # Module outputs
    │   └── firewall_nsg.tf       # Network security groups
    └── management/
        ├── main.tf               # Management instance
        ├── variables.tf          # Module variables
        └── outputs.tf           # Module outputs
```

## Roadmap

- [x] Remove SSH dependencies
- [x] Migrate to HCP Terraform
- [x] Implement dynamic DNS records
- [x] Add resource tagging
- [x] Add cost estimation
- [ ] Integrate HashiCorp Boundary for access
- [ ] Implement Sentinel policies
- [ ] Add monitoring and alerting
- [ ] Create disaster recovery procedures
- [ ] Set up multi-environment (dev/staging/prod)

## Contributing

1. Create feature branch
2. Make changes
3. Test locally with `terraform plan`
4. Submit pull request
5. Review HCP Terraform speculative plan in PR
6. Merge after approval

## License

[Your License Here]

## Contact

[Your Contact Information]

---

**Last Updated**: October 2025
**Terraform Version**: >= 1.5.0
**OCI Provider Version**: >= 5.0.0
**Managed By**: HCP Terraform (Terraform Cloud)
