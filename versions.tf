terraform {
  required_providers {
    # aviatrix = {
    #   source = "aviatrixsystems/aviatrix"
    # }\
    aviatrix = {
      source  = "aviatrix.com/aviatrix/aviatrix"
      version = "99.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.15.0"
    }
  }
  required_version = ">= 1.1.0"
}
