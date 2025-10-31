variable "compartment_ocid" {
  type        = string
  description = "OCID of the OCI compartment"
}

variable "availability_domain" {
  type        = string
  description = "Availability domain for the instance"
}

variable "image_id" {
  type        = string
  description = "OCID of the OS image to use"
}

variable "vcn_ocid" {
  type        = string
  description = "OCID of the Virtual Cloud Network"
}

variable "firewall_nsg_id" {
  type        = string
  description = "OCID of the firewall Network Security Group"
}

variable "public_subnet_id" {
  type        = string
  description = "OCID of the public subnet"
}

variable "private_subnet_id" {
  type        = string
  description = "OCID of the private subnet"
}
