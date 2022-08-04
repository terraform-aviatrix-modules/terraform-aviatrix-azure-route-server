# terraform-aviatrix-azure-route-server

### Description
This module deploys a VNET with Azure route server and integrates it with the provided Aviatrix transit through BGP over LAN. Make sure to use a transit instance size that allows for more than 4 interfaces (e.g. Standard_DS4_v2). An ExpressRoute Gateway (vng) is provisioned as well to facilitate attachment to the ExpressRoute circuit.

### Diagram
<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-azure-route-server/blob/main/img/diagram.png?raw=true" width="500">

### Compatibility
Module version | Terraform version | Controller version | Terraform provider version
:--- | :--- | :--- | :---
v1.0.0 | >= 1.0.0 | >= 6.8 | >= 2.23.0

### Usage Example
```
module "transit" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "2.2.0"

  cloud   = "Azure"
  region  = "West Europe"
  cidr    = "10.1.0.0/23"
  account = "Azure"

  local_as_number          = 65000
  insane_mode              = true
  enable_bgp_over_lan      = true
  bgp_lan_interfaces_count = 1
  instance_size            = "Standard_D4_v2"
}

module "azure_route_server" {
  source  = "terraform-aviatrix-modules/azure-route-server/aviatrix"
  version = "1.0.0"
  
  terraform-aviatrix-azure-route-server"
  name                = "myars"
  transit_vnet_obj    = module.transit.vpc
  transit_gw_obj      = module.transit.transit_gateway
  cidr                = "10.1.128.0/26"
  local_lan_ip        = "10.1.0.92"
  backup_local_lan_ip = "10.1.1.92"
}
```

### Variables
The following variables are required:

key | value
:--- | :---
name | Name to be used for Azure Route Server related components.
cidr | CIDR for VNET creation.
transit_vnet_obj | The entire VNET object as created by aviatrix_vpc resource.
transit_gw_obj | The entire gateway object as created by aviatrix_transit_gateway resource.
local_lan_ip | IP Address of Aviatrix transit GW BGP interface.
backup_local_lan_ip | IP Address of Aviatrix transit HAGW BGP interface.

The following variables are optional:

key | default | value 
:---|:---|:---
resource_group_name | | Resource group name, in case you want to use an existing resource group.
network_domain | | Network domain used for segmentation.
vng_sku | Standard | SKU to use to deploy the VNG.

### Outputs
This module will return the following outputs:

key | description
:---|:---
vng | Azure virtual network gateway with all attributes as created through the azurerm_virtual_network_gateway resource.
