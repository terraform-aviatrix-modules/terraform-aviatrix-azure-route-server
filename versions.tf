terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = ">= 2.23.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
  required_version = ">= 1.1.0"
}
