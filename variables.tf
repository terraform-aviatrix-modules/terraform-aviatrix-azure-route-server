variable "name" {
  description = "Name to be used for Azure Route Server related components."
  type        = string
}

variable "cidr" {
  description = "CIDR for VNET creation."
  type        = string

  validation {
    condition     = var.cidr != "" ? can(cidrnetmask(var.cidr)) : true
    error_message = "This does not like a valid CIDR."
  }

  validation {
    condition     = split("/", var.cidr)[1] <= 26
    error_message = "CIDR size too small. Needs to be at least a /26."
  }
}

variable "transit_vnet_obj" {
  description = "The entire VNET object as created by aviatrix_vpc resource."
}

variable "transit_gw_obj" {
  description = "The entire gateway object as created by aviatrix_transit_gateway resource."
}

variable "local_lan_ip" {
  description = "IP Address of Aviatrix transit GW BGP interface."
  type        = string
}

variable "backup_local_lan_ip" {
  description = "IP Address of Aviatrix transit HAGW BGP interface."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name, in case you want to use an existing resource group."
  type        = string
  default     = ""
  nullable    = false
}

variable "network_domain" {
  description = "Network domain used for segmentation"
  type        = string
  default     = ""
  nullable    = false
}

variable "vng_sku" {
  description = "SKU to use to deploy the VNG."
  type        = string
  default     = "Standard"
  nullable    = false
}

locals {
  existing_resource_group   = length(var.resource_group_name) > 0
  resource_group_name       = local.existing_resource_group ? var.resource_group_name : azurerm_resource_group.default[0].name
  region                    = var.transit_vnet_obj.region
  transit_vnet_id           = var.transit_vnet_obj.vpc_id
  transit_vnet_name         = var.transit_vnet_obj.name
  transit_gateway_name      = var.transit_gw_obj.gw_name
  transit_resource_group    = var.transit_vnet_obj.resource_group
  transit_resource_group_id = var.transit_vnet_obj.azure_vnet_resource_id
  transit_as_number         = var.transit_gw_obj.local_as_number
  segmentation_enabled      = var.transit_gw_obj.enable_segmentation
}
