terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = ">= 2.23.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.15.0"
    }
  }
  required_version = ">= 1.1.0"
}
