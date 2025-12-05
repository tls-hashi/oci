# OCI Infrastructure with HCP Vault Dynamic Credentials

This repository contains Terraform code to deploy a single Ubuntu compute instance on Oracle Cloud Infrastructure (OCI) using HCP Terraform and HCP Vault for secure credential management.

## Architecture

- **HCP Terraform** → Authenticates to **HCP Vault** via JWT/OIDC tokens
- **HCP Vault** → Stores OCI credentials securely at `oci/terraform`
- **Terraform** → Retrieves credentials at runtime (no static secrets)
- **OCI** → Deploys Ubuntu instance (Free Tier)

## Current Configuration

### Compute Instance
- **Instance Type**: VM.Standard.E2.1.Micro (x86 architecture)
- **Resources**: 1 OCPU, 1GB RAM (Fixed - Free Tier)
- **Region**: us-phoenix-1
- **Availability Domain**: AD-3 (emiq:PHX-AD-3)
- **OS**: Ubuntu 22.04 (x86_64)
- **Storage**: 50GB boot volume
- **Hostname**: ocloud1 (configurable via `instance_display_name` variable)
- **Pre-installed**: Apache2 web server
- **Login Message**: Displays IP addresses, hostname, and hardware resources

### Networking
- **VCN**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24
- **Internet Gateway**: For public internet access
- **Security List**: Allows SSH (22), HTTP (80), and HTTPS (443)

## Prerequisites

✅ **HCP Vault** (KV Cluster) configured with:
- KV v2 secrets engine mounted at `oci` path
- OCI credentials stored at `oci/terraform` with keys:
  - `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key`
  - `compartment_ocid`, `region`, `ssh_public_key`
- JWT auth method enabled at `auth/jwt`
- JWT role `terraform-oci` configured for workspace
- Policy `terraform-oci` with read access to `oci/data/terraform`

✅ **HCP Terraform** workspace "OCI" configured with:
- **Environment Variables** (required):
  - `TFC_VAULT_PROVIDER_AUTH` = `true`
  - `TFC_VAULT_ADDR` = `https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200`
  - `TFC_VAULT_NAMESPACE` = `admin`
  - `TFC_VAULT_RUN_ROLE` = `terraform-oci`

✅ **OCI Account** (Free Tier)
- API credentials configured
- us-phoenix-1 region enabled
- Compartment created

✅ **Local Tools** (for manual testing):
- Terraform CLI installed
- Vault CLI installed (optional)
- SSH key pair generated

## Deployment

### Automatic Deployment via HCP Terraform

1. **Commit and push code to repository:**
   ```bash
   git add .
   git commit -m "Deploy OCI instance with Vault dynamic credentials"
   git push origin main
   ```

2. **HCP Terraform will automatically:**
   - Authenticate to HCP Vault using JWT
   - Retrieve OCI credentials from Vault
   - Plan and apply the infrastructure

3. **Review and apply the plan in HCP Terraform UI**

### Manual Testing (Optional)

To test the configuration locally:
```bash
# Initialize Terraform
terraform init

# Create a plan
terraform plan

# Apply (requires manual Vault token)
terraform apply
```

## Security Features

- **Zero Static Credentials**: All OCI credentials retrieved dynamically from Vault
- **Short-Lived Tokens**: Vault tokens expire after 20 minutes
- **Workspace-Specific Access**: JWT role bound to specific workspace
- **Audit Trail**: All credential access logged in Vault
- **Latest Providers**: Using most recent versions with security fixes
- **Least Privilege**: Security lists only allow required ports

## Accessing the Instance

After deployment, SSH to your instance to see system information:

```bash
# SSH to the instance (use output from HCP Terraform)
ssh ubuntu@<instance_public_ip>
```

Upon login, you'll see a message displaying:
- Hostname (ocloud1 by default)
- Public and Private IP addresses
- CPU cores and memory

Test the web server:
```bash
curl http://<instance_public_ip>
```

## Outputs

The following outputs are available after deployment:

- `instance_public_ip` - Public IP address for SSH and HTTP access
- `instance_ocid` - Instance identifier
- `vcn_ocid` - VCN identifier
- `subnet_ocid` - Subnet identifier
- `availability_domain` - Deployment location
- `ubuntu_image_name` - OS image used
- `ssh_connection_command` - Ready-to-use SSH command
- `web_url` - URL to access the web server

## File Structure

```
.
├── README.md                           # This file
├── versions.tf                         # Terraform and provider versions
├── vault.tf                            # Vault provider configuration
├── network.tf                          # VCN, subnets, security, OCI provider
├── compute.tf                          # E2.1.Micro instance configuration
├── outputs.tf                          # Output definitions
├── variables.tf                        # Variable declarations
├── .gitignore                          # Git ignore rules
│
├── Setup & Configuration:
├── terraform-oci-policy.hcl            # Vault policy for OCI credentials
├── setup-vault-jwt-auth.sh             # Automated Vault setup script
├── verify-vault-setup.sh               # Vault configuration verification
├── jwt-role.json                       # JWT role configuration
├── demo-credential-rotation.sh         # Credential rotation demonstration
│
└── Documentation:
    ├── HCP-TERRAFORM-SETUP.md          # Workspace configuration guide
    ├── TROUBLESHOOTING.md              # Comprehensive troubleshooting
    ├── CREDENTIAL-ROTATION-DEMO.md     # Credential rotation guide
    └── WORKSPACE-VARIABLE-UPDATE.md    # Variable update instructions
```

## Credential Management

OCI credentials are managed in HCP Vault at:
- **Path**: `oci/terraform`
- **Fields**: tenancy_ocid, user_ocid, fingerprint, private_key, compartment_ocid, region

To update credentials:
```bash
vault kv put oci/terraform \
  tenancy_ocid="<new_value>" \
  user_ocid="<new_value>" \
  fingerprint="<new_value>" \
  private_key="<new_private_key>" \
  compartment_ocid="<value>" \
  region="<value>"
```

No changes needed in Terraform code - credentials are fetched at runtime.

## Initial Setup

### 1. Configure Vault (One-time Setup)

Run the automated setup script to configure Vault with JWT auth:

```bash
# Authenticate to Vault
vault login

# Run the setup script
./setup-vault-jwt-auth.sh
```

This will:
- Enable and configure JWT auth for HCP Terraform
- Create the `terraform-oci` policy with read permissions
- Create the `terraform-oci` JWT role with correct bound claims
- Verify the configuration

### 2. Verify Vault Configuration

```bash
./verify-vault-setup.sh
```

This checks all Vault components and confirms everything is configured correctly.

### 3. Configure HCP Terraform Workspace

Follow the instructions in `WORKSPACE-VARIABLE-UPDATE.md` to set the required environment variables.

## Customizing Instance Hostname

To deploy with a different hostname (e.g., ocloud2), update the variable in HCP Terraform workspace or create a `terraform.tfvars` file:

```hcl
instance_display_name = "ocloud2"
```

## Troubleshooting

### Vault Authentication Issues

**Error: "no vault token set on Client"**
- Ensure `TFC_VAULT_PROVIDER_AUTH=true` is set as an **Environment variable**
- Verify all 4 Vault-related environment variables are configured
- Check that variables are Environment variables, NOT Terraform variables
- See `WORKSPACE-VARIABLE-UPDATE.md` for detailed instructions

**Error: "permission denied"**
- Run `./verify-vault-setup.sh` to check Vault configuration
- Verify Vault policy allows reading `oci/data/terraform`
- Check JWT role `bound_claims` matches your organization and workspace
- Ensure JWT auth method is properly configured

### OCI Capacity Issues

**Error: "Out of host capacity"**
- **Current Solution**: Using E2.1.Micro in AD-3 (reliable availability)
- Try different availability domains if capacity issues occur
- See `TROUBLESHOOTING.md` for detailed guidance

### Instance Access Issues

**Cannot SSH to instance**
- Verify security list allows ingress on port 22 from your IP
- Check SSH public key is stored correctly in Vault at `oci/terraform`
- Wait 2-3 minutes after deployment for cloud-init to complete
- Use the `ssh_command` output for the correct connection string

**Web server not accessible**
- Verify security list allows HTTP (port 80)
- Wait for cloud-init to complete (check with SSH)
- Confirm Apache2 is running: `systemctl status apache2`

## Cost

This deployment uses Oracle Cloud's **Always Free Tier** resources:
- VM.Standard.E2.1.Micro: 1 OCPU and 1GB RAM (x86)
- 50GB boot volume
- 10TB egress per month

**Cost: $0.00/month** (within Free Tier limits)

## Security Best Practices

1. **Rotate credentials regularly** in Vault
2. **Review audit logs** in HCP Vault
3. **Monitor workspace runs** in HCP Terraform
4. **Use workspace-specific JWT roles** for isolation
5. **Enable MFA** for HCP portal access
6. **Restrict SSH access** by IP if possible

## Next Steps

- [ ] Configure monitoring and alerts
- [ ] Set up automated backups
- [ ] Implement HCP Boundary for secure access
- [ ] Deploy application workloads
- [ ] Configure SSL/TLS for HTTPS

## References

- [HCP Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Free Tier](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)

---

**Last Updated**: November 2024  
**Managed By**: HCP Terraform  
**Organization**: tls-hashi  
**Workspace**: OCI
