terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "ubuntu_image" {
  compartment_id            = var.compartment_ocid
  operating_system          = "Canonical Ubuntu"
  operating_system_version  = "24.04"
  shape                     = "VM.Standard.A1.Flex"
  sort_by                   = "TIMECREATED"
  sort_order                = "DESC"
}

data "oci_core_images" "nginx_image" {
  compartment_id            = var.compartment_ocid
  operating_system          = "Oracle Linux"
  operating_system_version  = "8"
  shape                     = "VM.Standard.A1.Flex"
  sort_by                   = "TIMECREATED"
  sort_order                = "DESC"
}

resource "oci_core_network_security_group" "firewall_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "firewall-nsg"

  lifecycle {
    prevent_destroy = false
  }
}

module "reverse_proxy" {
  source               = "./modules/reverse_proxy"
  compartment_ocid     = var.compartment_ocid
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  image_id             = data.oci_core_images.nginx_image.images[0].id
  vcn_ocid             = var.vcn_ocid
  firewall_nsg_id      = oci_core_network_security_group.firewall_nsg.id
  public_subnet_id     = oci_core_subnet.public_subnet.id
  private_subnet_id    = oci_core_subnet.private_subnet.id
  ssh_public_key_path  = var.ssh_public_key_path
  ssh_private_key_path = var.ssh_private_key_path
}

module "management" {
  source               = "./modules/management"
  compartment_ocid     = var.compartment_ocid
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  private_subnet_id    = oci_core_subnet.private_subnet.id
  image_id             = data.oci_core_images.ubuntu_image.images[0].id
  ssh_public_key_path  = var.ssh_public_key_path
  ssh_private_key_path = var.ssh_private_key_path
  bastion_host         = module.reverse_proxy.public_ip
}
