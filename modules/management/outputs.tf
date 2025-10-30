output "private_ip" {
  value       = oci_core_instance.management.private_ip
  description = "Private IP address of the management instance"
}

output "instance_id" {
  value       = oci_core_instance.management.id
  description = "OCID of the management instance (used for bastion access)"
}

output "public_ip" {
  value = data.oci_core_vnic.management_vnic.public_ip_address
}
