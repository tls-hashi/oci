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

variable "private_subnet_id" {
  type        = string
  description = "OCID of the private subnet"
}
