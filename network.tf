// ---------------------------
// VCN and Subnets
// ---------------------------

resource "oci_core_virtual_network" "default_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "twotwotwo-vcn"
  dns_label      = "twotwotwo"
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block     = "10.0.1.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "twotwotwo-public-subnet"
  dns_label      = "public"
  route_table_id = oci_core_route_table.public_rt.id
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block                  = "10.0.2.0/24"
  compartment_id              = var.compartment_ocid
  vcn_id                      = oci_core_virtual_network.default_vcn.id
  display_name                = "twotwotwo-private-subnet"
  prohibit_public_ip_on_vnic = true
  dns_label                   = "private"
  route_table_id              = oci_core_route_table.private_rt.id
}

// ---------------------------
// Gateways and Route Tables
// ---------------------------

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "twotwotwo-igw"
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "twotwotwo-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "222-gateway"
}

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "222-private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat.id
  }
}

# // ---------------------------
# // NSGs
# // ---------------------------

# resource "oci_core_network_security_group" "internal_comms" {
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_virtual_network.default_vcn.id
#   display_name   = "InternalComms"
# }

# resource "oci_core_network_security_group" "firewall_nsg" {
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_virtual_network.default_vcn.id
#   display_name   = "firewall-nsg"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# // ---------------------------
# // InternalComms NSG Rules
# // ---------------------------


# resource "oci_core_network_security_group_security_rule" "internal_all_egress" {
#   network_security_group_id = oci_core_network_security_group.internal_comms.id
#   direction                 = "EGRESS"
#   protocol                  = "all"
#   destination_type          = "NETWORK_SECURITY_GROUP"
#   destination               = oci_core_network_security_group.internal_comms.id
#   description               = "Allow all outbound traffic to InternalComms"
#   stateless                 = false
# }

# resource "oci_core_network_security_group_security_rule" "internal_tcp_3000_ingress" {
#   network_security_group_id = oci_core_network_security_group.internal_comms.id
#   direction                 = "INGRESS"
#   protocol                  = "6"
#   source_type               = "CIDR_BLOCK"
#   source                    = "10.0.0.0/16"
#   tcp_options {
#     destination_port_range {
#       min = 3000
#       max = 3000
#     }
#   }
#   description = "Allow internal TCP port 3000 ingress"
#   stateless   = false
# }


# // ---------------------------
# // Firewall NSG Rules
# // ---------------------------

# resource "oci_core_network_security_group_security_rule" "http_ingress" {
#   network_security_group_id = oci_core_network_security_group.firewall_nsg.id
#   direction                 = "INGRESS"
#   protocol                  = "6"
#   source                    = "0.0.0.0/0"
#   tcp_options {
#     destination_port_range {
#       min = 80
#       max = 80
#     }
#   }
#   description = "Allow HTTP inbound"
#   stateless   = false
# }

# resource "oci_core_network_security_group_security_rule" "https_ingress" {
#   network_security_group_id = oci_core_network_security_group.firewall_nsg.id
#   direction                 = "INGRESS"
#   protocol                  = "6"
#   source                    = "0.0.0.0/0"
#   tcp_options {
#     destination_port_range {
#       min = 443
#       max = 443
#     }
#   }
#   description = "Allow HTTPS inbound"
#   stateless   = false
# }

# resource "oci_core_network_security_group_security_rule" "ssh_ingress" {
#   network_security_group_id = oci_core_network_security_group.firewall_nsg.id
#   direction                 = "INGRESS"
#   protocol                  = "6"
#   source                    = "0.0.0.0/0"
#   tcp_options {
#     destination_port_range {
#       min = 22
#       max = 22
#     }
#   }
#   description = "Allow SSH inbound"
#   stateless   = false
# }

# resource "oci_core_network_security_group_security_rule" "internal_tcp_3000_egress" {
#   network_security_group_id = oci_core_network_security_group.firewall_nsg.id
#   direction                 = "EGRESS"
#   protocol                  = "6"
#   destination_type          = "CIDR_BLOCK"
#   destination               = "10.0.0.0/16"
#   tcp_options {
#     destination_port_range {
#       min = 3000
#       max = 3000
#     }
#   }
#   stateless = false

#   lifecycle {
#     ignore_changes = [
#       // For example, if the API omits a field on read that was set on creation,
#       // list that attribute here.
#       tcp_options[0].destination_port_range
#     ]
#   }
# }
