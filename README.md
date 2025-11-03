# OCI Infrastructure with HCP Vault Dynamic Credentials

This repository contains Terraform code to deploy a single Ubuntu compute instance on Oracle Cloud Infrastructure (OCI) using HCP Terraform and HCP Vault for secure credential management.

## Architecture

- **HCP Terraform** → Authenticates to **HCP Vault** via JWT tokens
- **HCP Vault** → Stores OCI credentials securely at `oci/terraform`
- **Terraform** → Retrieves credentials at runtime (no static secrets)
- **OCI** → Deploys Ubuntu instance on ARM-based A1.Flex shape (Free Tier)

## Infrastructure Components

### Networking
- **VCN**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24
- **Internet Gateway**: For public internet access
- **Security List**: Allows SSH (22), HTTP (80), and HTTPS (443)

### Compute
- **Instance Type**: VM.Standard.A1.Flex (ARM architecture)
- **Configuration**: 4 OCPUs, 24GB RAM (Free Tier)
- **OS**: Ubuntu 22.04
- **Storage**: 50GB boot volume
- **Pre-installed**: Apache2, curl, git

## Prerequisites

✅ HCP Vault Dedicated cluster configured with:
- KV v2 secrets engine at `oci` path
- OCI credentials stored at `oci/terraform`
- JWT auth method enabled
- JWT role `tfc-oci` configured for workspace
- Policy `terraform-oci` with read access

✅ HCP Terraform workspace "OCI" configured with environment variables:
- `TFC_VAULT_BACKED_DYNAMIC_CREDENTIALS=true`
- `TFC_VAULT_ADDR=https://tls-hashi-kv-public-vault-1caeb7d2.31341725.z1.hashicorp.cloud:8200`
- `TFC_VAULT_NAMESPACE=admin`
- `TFC_VAULT_RUN_ROLE=tfc-oci`

✅ OCI Account with API credentials stored in Vault

✅ SSH public key at `~/.ssh/id_rsa.pub`

## Deployment

### Automatic Deployment via HCP Terraform

1. **Commit and push code to GitHub:**
   ```bash
   git add versions.tf vault.tf network.tf compute.tf outputs.tf README.md
   git commit -m "Deploy Ubuntu A1.Flex instance with Vault dynamic credentials"
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

After deployment, use the outputs to access your instance:

```bash
# Get the public IP from Terraform outputs
# SSH to the instance
ssh ubuntu@<instance_public_ip>

# Test the web server
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
├── README.md           # This file
├── versions.tf         # Terraform and provider versions
├── vault.tf            # Vault provider and credential retrieval
├── network.tf          # VCN, subnets, security, OCI provider
├── compute.tf          # Compute instance configuration
├── outputs.tf          # Output definitions
└── .gitignore          # Git ignore rules
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

## Troubleshooting

### "no vault token set on Client"
- Verify all 4 environment variables are set in HCP Terraform workspace
- Ensure variables are set as Environment variables, not Terraform variables

### "permission denied"
- Check Vault policy allows reading `oci/data/terraform`
- Verify JWT role `bound_claims` matches your organization and workspace

### Instance not accessible via SSH
- Check security list allows ingress on port 22
- Verify SSH public key is correct in `~/.ssh/id_rsa.pub`
- Wait 2-3 minutes for cloud-init to complete

### A1.Flex shape not available
- A1.Flex (ARM) is part of Always Free tier
- Check regional availability
- Fallback to E2.1.Micro if needed

## Cost

This deployment uses Oracle Cloud's **Always Free Tier** resources:
- VM.Standard.A1.Flex: Up to 4 OCPUs and 24GB RAM (ARM)
- 50GB boot volume
- 10TB egress per month

**Estimated cost: $0.00/month** (within Free Tier limits)

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
