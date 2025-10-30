variable "compartment_ocid" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "image_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "bastion_host" {
  type        = string
  description = "Public IP address of the bastion (reverse_proxy) host."
}
