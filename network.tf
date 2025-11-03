# Virtual Cloud Network and Subnets
# Access to instances managed via HashiCorp Boundary (SSH removed)

resource "oci_core_virtual_network" "default_vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = local.compartment_ocid
  display_name   = "${var.naming_prefix}-vcn"
  dns_label      = var.naming_prefix

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-vcn"
      Environment = var.environment
    }
  )
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block     = var.public_subnet_cidr
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "${var.naming_prefix}-public-subnet"
  dns_label      = "public"
  route_table_id = oci_core_route_table.public_rt.id

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-public-subnet"
      Environment = var.environment
      Type        = "public"
    }
  )
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = var.private_subnet_cidr
  compartment_id             = local.compartment_ocid
  vcn_id                     = oci_core_virtual_network.default_vcn.id
  display_name               = "${var.naming_prefix}-private-subnet"
  prohibit_public_ip_on_vnic = true
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private_rt.id

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-private-subnet"
      Environment = var.environment
      Type        = "private"
    }
  )
}

# Internet Gateway for public subnet
resource "oci_core_internet_gateway" "igw" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "${var.naming_prefix}-igw"
  enabled        = true

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-igw"
      Environment = var.environment
    }
  )
}

# Public route table - routes to Internet Gateway
resource "oci_core_route_table" "public_rt" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "${var.naming_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-public-rt"
      Environment = var.environment
    }
  )
}

# NAT Gateway for private subnet outbound traffic
resource "oci_core_nat_gateway" "nat" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "${var.naming_prefix}-nat-gateway"

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-nat-gateway"
      Environment = var.environment
    }
  )
}

# Private route table - routes to NAT Gateway
resource "oci_core_route_table" "private_rt" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_virtual_network.default_vcn.id
  display_name   = "${var.naming_prefix}-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-private-rt"
      Environment = var.environment
    }
  )
}
