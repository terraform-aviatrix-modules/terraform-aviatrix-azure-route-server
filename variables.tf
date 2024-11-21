variable "name" {
  description = "Name to be used for Azure Route Server related components."
  type        = string
}

variable "cidr" {
  description = "CIDR for VNET creation."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "This does not like a valid CIDR."
  }

  validation {
    condition     = split("/", var.cidr)[1] <= 26
    error_message = "CIDR size too small. Needs to be at least a /26."
  }
}

variable "route_server_subnet" {
  description = "If provided, this is the subnet CIDR that will be used for the route server subnet."
  type        = string
  default     = ""

  validation {
    condition     = var.route_server_subnet != "" ? can(cidrnetmask(var.route_server_subnet)) : true
    error_message = "This does not like a valid CIDR."
  }

  validation {
    condition     = var.route_server_subnet != "" ? split("/", var.route_server_subnet)[1] <= 27 : true
    error_message = "CIDR size too small. Needs to be at least a /27."
  }
}

variable "vng_subnet" {
  description = "If provided, this is the subnet CIDR that will be used for the VNG subnet."
  type        = string
  default     = ""

  validation {
    condition     = var.vng_subnet != "" ? can(cidrnetmask(var.vng_subnet)) : true
    error_message = "This does not like a valid CIDR."
  }

  validation {
    condition     = var.vng_subnet != "" ? split("/", var.vng_subnet)[1] <= 27 : true
    error_message = "CIDR size too small. Needs to be at least a /27."
  }
}

variable "transit_vnet_obj" {
  description = "The entire VNET object as created by aviatrix_vpc resource."
}

variable "transit_gw_obj" {
  description = "The entire gateway object as created by aviatrix_transit_gateway resource."
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

variable "lan_interface_index" {
  description = "Determines which LAN interface will be used for terminating the BGP peering. Uses the first BGP interface by default (0)."
  type        = number
  default     = 0
  nullable    = false
}

variable "enable_bgp_peering" {
  description = "Toggle to enable/disable BGP peering between the Aviatrix transit and Azure route server. E.g. for migration scenario's."
  type        = bool
  default     = true
  nullable    = false
}

variable "enable_learned_cidrs_approval" {
  description = "Enable learned CIDRs approval for the connection."
  type        = bool
  default     = null
}

variable "manual_bgp_advertised_cidrs" {
  description = "Configure manual BGP advertised CIDRs for this connection."
  default     = null
}

variable "remote_vnet_traffic_enabled" {
  description = "Is remote vnet traffic that is used to configure this gateway to accept traffic from other Azure Virtual Networks enabled?"
  type        = bool
  default     = null
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
  bgp_lan_ip_list           = var.transit_gw_obj.bgp_lan_ip_list
  ha_bgp_lan_ip_list        = var.transit_gw_obj.ha_bgp_lan_ip_list
}
