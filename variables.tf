# OCI Authentication Variables
# These should be set as sensitive variables in HCP Terraform workspace

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the OCI tenancy"
  sensitive   = true
}

variable "user_ocid" {
  type        = string
  description = "OCID of the OCI user"
  sensitive   = true
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of the OCI API key"
  sensitive   = true
}

variable "private_key" {
  type        = string
  description = "Contents of the OCI API private key (not the file path)"
  sensitive   = true
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the OCI compartment where resources will be created"
}

variable "region" {
  type        = string
  description = "OCI region where resources will be deployed"
  default     = "us-phoenix-1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+$", var.region))
    error_message = "Region must be a valid OCI region identifier (e.g., us-phoenix-1)."
  }
}

# Network Configuration Variables

variable "vcn_cidr" {
  type        = string
  description = "CIDR block for the Virtual Cloud Network"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "VCN CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid IPv4 CIDR block."
  }
}

# Resource Naming Variables

variable "naming_prefix" {
  type        = string
  description = "Prefix for resource names (e.g., 'twotwotwo' or '222')"
  default     = "twotwotwo"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.naming_prefix))
    error_message = "Naming prefix must contain only lowercase letters and numbers."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Resource Tagging

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    ManagedBy = "Terraform"
    Platform  = "HCP-Terraform"
  }
}

# DNS Configuration

variable "dns_zone_name" {
  type        = string
  description = "DNS zone name"
  default     = "2two2.me"
}
