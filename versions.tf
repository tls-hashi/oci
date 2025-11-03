terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "tls-hashi"
    workspaces {
      name = "OCI"
    }
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.24.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.5.0"
    }
  }
}
