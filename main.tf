data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "default" {
  count    = local.existing_resource_group ? 0 : 1
  name     = var.name
  location = var.region
}

resource "azurerm_virtual_network" "default" {
  name                = format("%s-ars-vnet", var.name)
  address_space       = [var.cidr]
  resource_group_name = local.resource_group_name
  location            = var.region
}

resource "azurerm_subnet" "default" {
  name                 = "RouteServerSubnet"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = local.resource_group_name
  address_prefixes     = [var.cidr]
}


resource "azurerm_public_ip" "default" {
  name                = format("%s-ars-pip", var.name)
  resource_group_name = local.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "default" {
  name                             = format("%s-ars", var.name)
  resource_group_name              = local.resource_group_name
  location                         = var.region
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.default.id
  subnet_id                        = azurerm_subnet.default.id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_virtual_network_peering" "default-1" {
  name                      = format("%s-peertransittoars", var.name)
  resource_group_name       = var.transit_vnet_obj.resource_group
  virtual_network_name      = var.transit_vnet_obj.name
  remote_virtual_network_id = azurerm_virtual_network.default.id
  use_remote_gateways       = true

  depends_on = [
    azurerm_express_route_gateway.default
  ]
}

resource "azurerm_virtual_network_peering" "default-2" {
  name                      = format("%s-peerarstotransit", var.name)
  resource_group_name       = local.resource_group_name
  virtual_network_name      = azurerm_virtual_network.default.name
  remote_virtual_network_id = var.transit_vnet_obj.azure_vnet_resource_id
  allow_gateway_transit     = true

  depends_on = [
    azurerm_express_route_gateway.default
  ]
}

resource "azurerm_route_server_bgp_connection" "default" {
  name            = format("%s-ars-bgp", var.name)
  route_server_id = azurerm_route_server.default.id
  peer_asn        = 65501
  peer_ip         = "169.254.21.5"
}

resource "aviatrix_transit_external_device_conn" "default" {
  vpc_id                   = var.transit_vnet_obj.vpc_id
  connection_name          = format("%s-ars-bgp", var.name)
  gw_name                  = var.transit_gw_obj.gw_name
  connection_type          = "bgp"
  tunnel_protocol          = "LAN"
  remote_vpc_name          = format("%s:%s:%s", azurerm_virtual_network.default.name, local.resource_group_name, data.azurerm_subscription.current.subscription_id)
  ha_enabled               = true
  bgp_local_as_num         = var.transit_gw_obj.local_as_number
  bgp_remote_as_num        = "65515"
  backup_bgp_remote_as_num = "65515"
  backup_remote_lan_ip     = tolist(azurerm_route_server.default.virtual_router_ips)[1]
  remote_lan_ip            = tolist(azurerm_route_server.default.virtual_router_ips)[0]
  # local_lan_ip              = var.transit_gw_obj.bgp_lan_ip_list[0]
  # backup_local_lan_ip       = var.transit_gw_obj.ha_bgp_lan_ip_list[0]
  enable_bgp_lan_activemesh = true

  depends_on = [
    azurerm_virtual_network_peering.default-1,
    azurerm_virtual_network_peering.default-2,
  ]
}

#TODO: Implement segmentation

resource "azurerm_express_route_gateway" "default" {
  name                = "expressRoute1"
  resource_group_name = local.resource_group_name
  location            = var.region
  virtual_hub_id      = azurerm_route_server.default.id
  scale_units         = 1
}
