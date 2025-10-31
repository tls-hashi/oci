# Reverse proxy instance in public subnet
# Access will be provided via HashiCorp Boundary (future implementation)

resource "oci_core_instance" "reverse_proxy" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "twotwotwo-reverse-proxy"
  shape               = "VM.Standard.E2.1.Micro"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 2
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  create_vnic_details {
    subnet_id        = var.public_subnet_id
    assign_public_ip = true
    display_name     = "twotwotwo-reverse-proxy-public-vnic"
    nsg_ids          = [oci_core_network_security_group.firewall_nsg.id]
  }

  metadata = {
    hostname_label = "jellybean"
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

resource "oci_core_vnic_attachment" "private_vnic" {
  instance_id = oci_core_instance.reverse_proxy.id

  create_vnic_details {
    subnet_id              = var.private_subnet_id
    assign_public_ip       = false
    display_name           = "twotwotwo-reverse-proxy-private-vnic"
    skip_source_dest_check = true
  }
}

data "oci_core_vnic_attachments" "reverse_proxy_vnics" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.reverse_proxy.id
}

data "oci_core_vnic" "reverse_proxy_private_vnic" {
  vnic_id = data.oci_core_vnic_attachments.reverse_proxy_vnics.vnic_attachments[0].vnic_id
}
