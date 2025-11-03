# Data source to get the latest Ubuntu image
data "oci_core_images" "ubuntu" {
  compartment_id           = local.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Data source to get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_ocid
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
      - echo '<html><head><title>OCI Instance</title></head><body><h1>Welcome to Oracle Cloud Infrastructure</h1><p>Deployed via HCP Terraform with Vault Dynamic Credentials</p></body></html>' > /var/www/html/index.html
      - systemctl restart apache2
  EOF
}

# Compute Instance - Ubuntu on A1.Flex (ARM) Free Tier
# Try different availability domains if capacity is low
resource "oci_core_instance" "main" {
  compartment_id      = local.compartment_ocid
  # Try AD-2 first (often has more capacity than AD-1)
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
  display_name        = "ubuntu-a1-instance"
  shape               = "VM.Standard.A1.Flex"

  # Shape configuration for Flex shapes
  # Reduced to 2 OCPUs / 12GB RAM for better availability (still free tier)
  shape_config {
    ocpus         = 1
    memory_in_gbs = 1
  }

  # Boot volume source
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 50
  }

  # Network configuration
  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "primary-vnic"
    hostname_label   = "ubuntu-instance"
  }

  # SSH key for access
  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }

  # Prevent accidental deletion
  preserve_boot_volume = false

  # Tags for organization
  freeform_tags = {
    "Environment" = "Production"
    "Project"     = "HCP-Vault-Dynamic-Credentials"
    "ManagedBy"   = "Terraform"
  }
}
