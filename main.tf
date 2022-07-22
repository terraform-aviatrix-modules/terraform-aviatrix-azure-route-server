resource "azurerm_resource_group" "default" {
  count    = local.existing_resource_group ? 0 : 1
  name     = var.name
  location = var.region
}

resource "azurerm_virtual_network" "default" {
  name                = format("%s-ars-vnet", var.name)
  address_space       = [var.cidr]
  resource_group_name = local.resource_group_name
  location            = azurerm_resource_group.default.location
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
  name                 = format("%s-ars", var.name)
  resource_group_name  = local.resource_group_name
  location             = var.region
  sku                  = "Standard"
  public_ip_address_id = azurerm_public_ip.default.id
  subnet_id            = azurerm_subnet.default.id
}

resource "azurerm_virtual_network_peering" "default-1" {
  name                      = format("%s-peertransittoars", var.name)
  resource_group_name       = azurerm_resource_group.default.name
  virtual_network_name      = var.transit_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.default.id
}

resource "azurerm_virtual_network_peering" "default-2" {
  name                      = format("%s-peerarstotransit", var.name)
  resource_group_name       = azurerm_resource_group.default.name
  virtual_network_name      = azurerm_virtual_network.default.name
  remote_virtual_network_id = var.transit_vnet_id
}

resource "azurerm_route_server_bgp_connection" "example" {
  name            = format("%s-ars-bgp", var.name)
  route_server_id = azurerm_route_server.example.id
  peer_asn        = 65501
  peer_ip         = "169.254.21.5"
}

#BGP over LAN ding
resource "aviatrix_transit_external_device_conn" "bgpolan-connection" {
  vpc_id                    = var.transit_vnet_id
  connection_name           = format("%s-ars-bgp", var.name)
  gw_name                   = var.transit_gw
  connection_type           = "bgp"
  tunnel_protocol           = "LAN"
  remote_vpc_name           = "vnet-name:resource-group-name:subscription-id"
  bgp_local_as_num          = "65001"
  bgp_remote_as_num         = "65011"
  local_lan_ip              = "172.12.11.1"
  remote_lan_ip             = "172.12.21.4"
  ha_enabled                = true
  backup_bgp_remote_as_num  = "65011"
  backup_local_lan_ip       = "172.12.12.1"
  backup_remote_lan_ip      = "172.12.22.4"
  enable_bgp_lan_activemesh = true
}


