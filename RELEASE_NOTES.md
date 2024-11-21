# terraform-aviatrix-azure-route-server - release notes

## v1.0.3

### Add support for remote_vnet_traffic_enabled
Allows you to toggle remote_vnet_traffic_enabled on the VNG.

## v1.0.2

### Add support for enable_learned_cidrs_approval
Allows you to toggle on connection based cidr approval on the BGP peering on the Aviatrix transit side.

### Add option to toggle BGP peering
Using the enable_bgp_peering argument, the module can be instructed to create all resources except the BGP peering. This may be useful in migration scenario's where you want to stage the environment before actually shifting traffic.

### Add support to custmize subnets
By default, the provided CIDR for the VNET will be split in 2 subnets. One for VNG the second for ARS. In some cases you might want to customize this. Using route_server_subnet and vng_subnet allows you to explicitly set the subnets to be created for these functions.

## v1.0.1

### Automatically find LAN IP addresses based on new Transit Gateway attribute

### Implement support for manual_bgp_advertised_cidrs

## v1.0.0 Initial release
