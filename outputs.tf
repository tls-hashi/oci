# Output the public IP address of the instance
output "instance_public_ip" {
  description = "Public IP address of the compute instance"
  value       = oci_core_instance.main.public_ip
}

# Output the instance OCID
output "instance_ocid" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.main.id
}

# Output the VCN OCID
output "vcn_ocid" {
  description = "OCID of the Virtual Cloud Network"
  value       = oci_core_vcn.main.id
}

# Output the subnet OCID
output "subnet_ocid" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.public.id
}

# Output the availability domain used
output "availability_domain" {
  description = "Availability domain where the instance is deployed"
  value       = oci_core_instance.main.availability_domain
}

# Output the Ubuntu image used
output "ubuntu_image_name" {
  description = "Name of the Ubuntu image used"
  value       = data.oci_core_images.ubuntu.images[0].display_name
}

# Output SSH connection command
output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${oci_core_instance.main.public_ip}"
}

# Output web URL
output "web_url" {
  description = "URL to access the web server"
  value       = "http://${oci_core_instance.main.public_ip}"
}
