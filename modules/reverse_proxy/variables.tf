variable "public_subnet_id" {
  description = "OCID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "OCID of the private subnet"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain to deploy into"
  type        = string
}

variable "image_id" {
  description = "OCID of the image to use"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}

variable "vcn_ocid" {
  description = "The OCID of the VCN"
  type        = string
}

variable "firewall_nsg_id" {
  description = "NSG to attach to the reverse proxy instance"
  type        = string
}
