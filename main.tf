resource "azurerm_resource_group" "default" {
  count    = local.existing_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.region
}

resource "azurerm_virtual_network" "default" {
  name                = "default-vn"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = local.existing_resource_group ? azurerm_resource_group.default[0].name : 0
  location            = azurerm_resource_group.default.location

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "RouteServerSubnet"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "example" {
  name                             = "example-routerserver"
  resource_group_name              = azurerm_resource_group.example.name
  location                         = azurerm_resource_group.example.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.example.id
  subnet_id                        = azurerm_subnet.example.id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_virtual_network_peering" "default-1" {
  name                      = "peertransittoars"
  resource_group_name       = azurerm_resource_group.default.name
  virtual_network_name      = azurerm_virtual_network.default-1.name
  remote_virtual_network_id = azurerm_virtual_network.default-2.id
}

resource "azurerm_virtual_network_peering" "default-2" {
  name                      = "peerarstotransit"
  resource_group_name       = azurerm_resource_group.default.name
  virtual_network_name      = azurerm_virtual_network.default-2.name
  remote_virtual_network_id = azurerm_virtual_network.default-1.id
}

#BGP over LAN ding
resource "aviatrix_transit_external_device_conn" "bgpolan-connection" {
  vpc_id                    = aviatrix_transit_gateway.transit-gateway.vpc_id
  connection_name           = "my_conn"
  gw_name                   = aviatrix_transit_gateway.transit-gateway.gw_name
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


