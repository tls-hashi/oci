# OCI Provider - Credentials from Vault
provider "oci" {
  tenancy_ocid = local.tenancy_ocid
  user_ocid    = local.user_ocid
  fingerprint  = local.fingerprint
  private_key  = local.private_key
  region       = local.region
}

# Virtual Cloud Network (VCN)
resource "oci_core_vcn" "main" {
  compartment_id = local.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "main-vcn"
  dns_label      = "mainvcn"
}

# Internet Gateway for public internet access
resource "oci_core_internet_gateway" "main" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main-internet-gateway"
  enabled        = true
}

# Route Table for internet access
resource "oci_core_route_table" "public" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# Security List for public subnet
resource "oci_core_security_list" "public" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "public-security-list"

  # Ingress Rules
  # SSH access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Egress Rules
  # Allow all outbound traffic
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }
}

# Public Subnet
resource "oci_core_subnet" "public" {
  compartment_id             = local.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "public-subnet"
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
}
