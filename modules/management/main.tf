# Management instance in private subnet
# Access will be provided via HashiCorp Boundary (future implementation)

resource "oci_core_instance" "management" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "twotwotwo-management"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 3
    memory_in_gbs = 22
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  create_vnic_details {
    subnet_id              = var.private_subnet_id
    assign_public_ip       = false
    display_name           = "management-private-vnic"
    skip_source_dest_check = true
  }

  metadata = {
    hostname_label = "mgmt"
  }

  agent_config {
    is_management_disabled = false
    is_monitoring_disabled = false
  }

  lifecycle {
    ignore_changes = [
      metadata,
    ]
  }
}

data "oci_core_vnic_attachments" "management_vnics" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.management.id
}

data "oci_core_vnic" "management_vnic" {
  vnic_id = data.oci_core_vnic_attachments.management_vnics.vnic_attachments[0].vnic_id
}
