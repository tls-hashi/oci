# Instance outputs
output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.main.private_ip
}

output "instance_state" {
  description = "Current state of the instance"
  value       = oci_core_instance.main.state
}

output "availability_domain" {
  description = "Availability domain where the instance is deployed"
  value       = oci_core_instance.main.availability_domain
}

# Network outputs
output "vcn_id" {
  description = "OCID of the Virtual Cloud Network"
  value       = oci_core_vcn.main.id
}

output "subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.public.id
}

# Connection outputs
output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${oci_core_instance.main.public_ip}"
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${oci_core_instance.main.public_ip}"
}

# Image output
output "ubuntu_image_name" {
  description = "Name of the Ubuntu ARM image used"
  value       = data.oci_core_images.ubuntu_arm.images[0].display_name
}
