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
      version = "~> 7.24.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.3.0"
    }
  }
}
