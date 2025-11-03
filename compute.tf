# Availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_ocid
}

# Latest Ubuntu 22.04 ARM image for A1.Flex
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = local.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-aarch64.*"]
    regex  = true
  }
}

# Cloud init configuration
locals {
  ssh_public_key = local.oci_creds.ssh_public_key
  
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - apache2
    runcmd:
      - systemctl enable apache2
      - systemctl start apache2
      - echo '<h1>Welcome to OCI</h1><p>ARM A1.Flex - Deployed via HCP Terraform + Vault</p><p>4 OCPUs / 24GB RAM</p>' > /var/www/html/index.html
  EOF
}

# Compute instance - A1.Flex ARM (full free tier)
resource "oci_core_instance" "main" {
  compartment_id      = local.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
  display_name        = "ubuntu-arm-instance"
  shape               = "VM.Standard.A1.Flex"
  
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }
  
  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 50
  }
  
  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = "ubuntu-arm-instance"
  }
  
  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }
  
  preserve_boot_volume = false
  
  freeform_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "HCP-Vault-Dynamic-Credentials"
    "Shape"     = "A1.Flex-ARM"
  }
  
  timeouts {
    create = "30m"
  }
}
