output "public_ip" {
  value       = oci_core_instance.reverse_proxy.public_ip
  description = "Public IP address of the reverse proxy instance"
}

output "private_ip" {
  value       = data.oci_core_vnic.reverse_proxy_private_vnic.private_ip_address
  description = "Private IP address of the reverse proxy instance"
}

output "instance_id" {
  value       = oci_core_instance.reverse_proxy.id
  description = "OCID of the reverse proxy instance"
}

output "compartment_id" {
  value       = oci_core_instance.reverse_proxy.compartment_id
  description = "Compartment OCID of the reverse proxy instance"
}
