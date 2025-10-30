// Public-facing NSG for HTTP, HTTPS, and SSH
resource "oci_core_network_security_group" "firewall_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_ocid
  display_name   = "firewall-nsg"

  lifecycle {
    prevent_destroy = false
  }
}

resource "oci_core_network_security_group_security_rule" "http_ingress" {
  network_security_group_id = oci_core_network_security_group.firewall_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"              // TCP
  source                    = "0.0.0.0/0"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
  description = "Allow HTTP inbound"
  stateless   = false
}

resource "oci_core_network_security_group_security_rule" "https_ingress" {
  network_security_group_id = oci_core_network_security_group.firewall_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"              // TCP
  source                    = "0.0.0.0/0"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
  description = "Allow HTTPS ingress"
  stateless   = false
}

resource "oci_core_network_security_group_security_rule" "ssh_ingress" {
  network_security_group_id = oci_core_network_security_group.firewall_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"              // TCP
  source                    = "0.0.0.0/0"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  description = "Allow SSH ingress"
  stateless   = false
}

// Internal Communications NSG and its rules
resource "oci_core_network_security_group" "internal_comms" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_ocid  // Updated to use var.vcn_id
  display_name   = "internal-comms"

  lifecycle {
    prevent_destroy = false
  }
}

resource "oci_core_network_security_group_security_rule" "internal_tcp_3000_ingress" {
  network_security_group_id = oci_core_network_security_group.internal_comms.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "10.0.0.0/16"   // Adjust to your internal CIDR
  tcp_options {
    destination_port_range {
      min = 3000
      max = 3000
    }
  }
  description = "Allow internal TCP port 3000 ingress"
  stateless   = false
}

resource "oci_core_network_security_group_security_rule" "internal_tcp_3000_egress" {
  network_security_group_id = oci_core_network_security_group.internal_comms.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination_type          = "CIDR_BLOCK"
  destination               = "10.0.0.0/16"   // Adjust as needed
  tcp_options {
    destination_port_range {
      min = 3000
      max = 3000
    }
  }
  stateless = false
  lifecycle {
    ignore_changes = [
      tcp_options[0].destination_port_range
    ]
  }
}

resource "oci_core_network_security_group_security_rule" "webhook_ingress" {
  network_security_group_id = oci_core_network_security_group.internal_comms.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"  // Adjust source CIDR if needed
  tcp_options {
    destination_port_range {
      min = 9000
      max = 9000
    }
  }
  description = "Allow webhook notifications on port 9000"
  stateless   = false
}