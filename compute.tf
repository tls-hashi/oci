# Alternative compute configuration using E2.1.Micro (x86 Free Tier)
# Rename to compute.tf to use this instead of A1.Flex

# NOTE: E2.1.Micro can ONLY be created in AD-3 (emiq:PHX-AD-3)

# Availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_ocid
}

# Latest Ubuntu 22.04 x86 image for E2.1.Micro
data "oci_core_images" "ubuntu_x86" {
  compartment_id           = local.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-\\d{4}\\.\\d{2}\\.\\d{2}-\\d+$"]
    regex  = true
  }
}

# Instance names
locals {
  ssh_public_key = local.oci_creds.ssh_public_key
  instance_names = ["ocloud1", "ocloud2"]
}

# Cloud-init configuration function
locals {
  cloud_init = { for name in local.instance_names :
    name => templatefile("${path.module}/cloud-init.tftpl", {
      hostname = name
    })
  }
}

# Compute instances - E2.1.Micro (x86, must be in AD-3)
resource "oci_core_instance" "main" {
  count = length(local.instance_names)

  compartment_id      = local.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name # MUST be index 2 (AD-3)
  display_name        = local.instance_names[count.index]
  shape               = "VM.Standard.E2.1.Micro"

  # No shape_config needed for Micro instances - fixed size

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_x86.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = local.instance_names[count.index]
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = base64encode(local.cloud_init[local.instance_names[count.index]])
  }

  preserve_boot_volume = false

  freeform_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "HCP-Vault-Dynamic-Credentials"
    "Instance"  = local.instance_names[count.index]
  }

  timeouts {
    create = "30m"
  }
}
