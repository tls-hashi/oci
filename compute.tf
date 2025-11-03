# Data source to get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_ocid
}

# Data source to get the latest Ubuntu ARM image for A1.Flex
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = local.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  
  # Filter for ARM architecture
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-aarch64.*"]
    regex  = true
  }
}

# Retrieve SSH public key from Vault
locals {
  ssh_public_key = local.oci_creds.ssh_public_key
}

# Cloud-init script to set up the instance
locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - apache2
      - curl
      - git
    runcmd:
      - systemctl enable apache2
      - systemctl start apache2
      - echo '<html><head><title>OCI Instance</title></head><body><h1>Welcome to Oracle Cloud Infrastructure</h1><p>Deployed via HCP Terraform with Vault Dynamic Credentials</p><p>Instance: ${var.instance_display_name}</p></body></html>' > /var/www/html/index.html
      - systemctl restart apache2
  EOF
}

# Compute Instance - Ubuntu on A1.Flex (ARM) Free Tier
resource "oci_core_instance" "main" {
  compartment_id = local.compartment_ocid
  
  # Try different ADs with fallback - don't hardcode AD index
  # Start with AD-3 (index 2), fall back to others if that fails
  availability_domain = try(
    data.oci_identity_availability_domains.ads.availability_domains[2].name,
    data.oci_identity_availability_domains.ads.availability_domains[1].name,
    data.oci_identity_availability_domains.ads.availability_domains[0].name
  )
  
  display_name = var.instance_display_name
  shape        = "VM.Standard.A1.Flex"
  
  # Shape configuration for A1.Flex
  # IMPORTANT: A1.Flex requires minimum 6GB RAM per OCPU (1:6 ratio)
  # Free tier allows up to 4 OCPUs and 24GB RAM total
  shape_config {
    ocpus         = 1
    memory_in_gbs = 6  # Minimum 6GB for 1 OCPU
  }
  
  # Boot volume source
  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 50
  }
  
  # Network configuration
  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "primary-vnic"
    hostname_label   = "ubuntu-instance"
  }
  
  # SSH key and cloud-init configuration
  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }
  
  # Don't preserve boot volume on termination (for testing)
  preserve_boot_volume = false
  
  # Tags for organization
  freeform_tags = {
    "Environment" = "Production"
    "Project"     = "HCP-Vault-Dynamic-Credentials"
    "ManagedBy"   = "Terraform"
    "Shape"       = "A1.Flex"
    "OS"          = "Ubuntu-22.04-ARM"
  }
  
  # Lifecycle rules to help with capacity issues
  lifecycle {
    # Ignore availability_domain changes to allow manual intervention
    ignore_changes = [
      availability_domain
    ]
    
    # Create new instance before destroying old one (if updating)
    create_before_destroy = false
  }
  
  # Add timeouts for capacity-constrained resources
  timeouts {
    create = "30m"  # Allow extra time for capacity to become available
  }
}

# Output instance details
output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.main.private_ip
}

output "instance_state" {
  description = "Current state of the instance"
  value       = oci_core_instance.main.state
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${oci_core_instance.main.public_ip}"
}

output "web_url" {
  description = "URL to access the Apache web server"
  value       = "http://${oci_core_instance.main.public_ip}"
}