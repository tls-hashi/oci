output "reverse_proxy_ip" {
  value = module.reverse_proxy.public_ip
}

output "mgmt_ip" {
  value = module.management.public_ip
}

output "reverse_proxy_private_ip" {
  value       = module.reverse_proxy.private_ip
  description = "Private IP of the NGINX reverse proxy instance"
}

output "mgmt_private_ip" {
  value       = module.management.private_ip
  description = "Private IP of the Gitea + Ansible instance"
}

output "private_subnet_cidr" {
  value = oci_core_subnet.private_subnet.cidr_block
}

output "vcn_id" {
  value = oci_core_virtual_network.default_vcn.id
}

// Additional network outputs

output "public_subnet_cidr" {
  value       = oci_core_subnet.public_subnet.cidr_block
  description = "CIDR block of the public subnet"
}

output "private_subnet_id" {
  value       = oci_core_subnet.private_subnet.id
  description = "OCID of the private subnet"
}

output "vcn_cidr" {
  value       = oci_core_virtual_network.default_vcn.cidr_block
  description = "CIDR block of the VCN"
}

output "internet_gateway_id" {
  value       = oci_core_internet_gateway.igw.id
  description = "OCID of the Internet Gateway"
}

output "public_rt_id" {
  value       = oci_core_route_table.public_rt.id
  description = "OCID of the public route table"
}

output "private_rt_id" {
  value       = oci_core_route_table.private_rt.id
  description = "OCID of the private route table (with NAT routing)"
}

output "nat_gateway_id" {
  value       = oci_core_nat_gateway.nat.id
  description = "OCID of the NAT Gateway"
}

#output "internal_comms_nsg_id" {
#  value       = oci_core_network_security_group.internal_comms.id
#  description = "OCID of the InternalComms Network Security Group"
#}
