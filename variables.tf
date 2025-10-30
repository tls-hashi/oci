variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "ssh_public_key_path" {}
variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}
variable "project_id" {}