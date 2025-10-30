resource "oci_dns_zone" "main_zone" {
  compartment_id = var.compartment_ocid
  name           = "2two2.me"
  zone_type      = "PRIMARY"
}

resource "oci_dns_rrset" "reverse_proxy" {
  zone_name_or_id = oci_dns_zone.main_zone.id
  domain          = "2two2.me"
  rtype           = "A"

  items {
    domain = "2two2.me"
    rdata  = "158.101.17.204"
    ttl    = 300
    rtype  = "A"
  }
}

resource "oci_dns_rrset" "servarr" {
  zone_name_or_id = oci_dns_zone.main_zone.id
  domain          = "media.2two2.me"
  rtype           = "A"

  items {
    domain = "media.2two2.me"
    rdata  = "10.0.2.199"
    ttl    = 300
    rtype  = "A"
  }
}

resource "oci_dns_rrset" "git" {
  zone_name_or_id = oci_dns_zone.main_zone.id
  domain          = "git.2two2.me"
  rtype           = "A"

  items {
    domain = "git.2two2.me"
    rdata  = "10.0.2.187"
    ttl    = 300
    rtype  = "A"
  }
}
