# DNS Zone and Records
# Dynamic IP addresses from Terraform outputs

resource "oci_dns_zone" "main_zone" {
  compartment_id = var.compartment_ocid
  name           = var.dns_zone_name
  zone_type      = "PRIMARY"

  freeform_tags = merge(
    var.tags,
    {
      Name        = "${var.naming_prefix}-dns-zone"
      Environment = var.environment
    }
  )
}

# Root domain A record pointing to reverse proxy public IP
resource "oci_dns_rrset" "root_domain" {
  zone_name_or_id = oci_dns_zone.main_zone.id
  domain          = var.dns_zone_name
  rtype           = "A"

  items {
    domain = var.dns_zone_name
    rdata  = module.reverse_proxy.public_ip
    ttl    = 300
    rtype  = "A"
  }
}

# Media subdomain A record
# TODO: Update rdata to reference actual media server IP once deployed
resource "oci_dns_rrset" "media_subdomain" {
  zone_name_or_id = oci_dns_zone.main_zone.id
  domain          = "media.${var.dns_zone_name}"
  rtype           = "A"

  items {
    domain = "media.${var.dns_zone_name}"
    rdata  = "10.0.2.199" # TODO: Replace with dynamic reference when media server is managed by Terraform
    ttl    = 300
    rtype  = "A"
  }
}

# Git subdomain A record
# TODO: Update rdata to reference actual git server IP once deployed
resource "oci_dns_rrset" "git_subdomain" {
  zone_name_or_id = oci_dns_zone.main_zone.id
  domain          = "git.${var.dns_zone_name}"
  rtype           = "A"

  items {
    domain = "git.${var.dns_zone_name}"
    rdata  = "10.0.2.187" # TODO: Replace with dynamic reference when git server is managed by Terraform
    ttl    = 300
    rtype  = "A"
  }
}
