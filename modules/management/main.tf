provider "google" {
  project = var.project_id
  region  = var.region
}

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
    ssh_authorized_keys = file(var.ssh_public_key_path)
    hostname_label      = "mgmt"
  }

  agent_config {
    is_management_disabled  = false
    is_monitoring_disabled  = false

    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
  }

  connection {
    type                = "ssh"
    host                = self.private_ip
    user                = "ubuntu"
    private_key         = file(var.ssh_private_key_path)
    timeout             = "5m"

    bastion_host        = var.bastion_host
    bastion_user        = "ubuntu"
    bastion_private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = var.ssh_private_key_path
    destination = "/home/ubuntu/.ssh/id_rsa"
  }
}

data "oci_core_vnic_attachments" "management_vnics" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.management.id
}

// Use the primary VNIC
data "oci_core_vnic" "management_vnic" {
  vnic_id = data.oci_core_vnic_attachments.management_vnics.vnic_attachments[0].vnic_id
}

resource "google_compute_instance" "reverse_proxy" {
  name         = "reverse-proxy"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

