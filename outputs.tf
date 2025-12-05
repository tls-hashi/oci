# Instance outputs
output "instances" {
  description = "Map of instance details by hostname"
  value = {
    for idx, instance in oci_core_instance.main :
    local.instance_names[idx] => {
      id         = instance.id
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
      state      = instance.state
    }
  }
}

output "availability_domain" {
  description = "Availability domain where the instances are deployed"
  value       = oci_core_instance.main[0].availability_domain
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
output "ssh_commands" {
  description = "SSH commands to connect to each instance"
  value = {
    for idx, instance in oci_core_instance.main :
    local.instance_names[idx] => "ssh ubuntu@${instance.public_ip}"
  }
}

output "web_urls" {
  description = "URLs to access the web servers"
  value = {
    for idx, instance in oci_core_instance.main :
    local.instance_names[idx] => "http://${instance.public_ip}"
  }
}

# # Image output
# output "ubuntu_image_name" {
#   description = "Name of the Ubuntu image used"
#   value       = data.oci_core_images.ubuntu_arm.images[0].display_name
# }
