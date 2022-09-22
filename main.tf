#Generic Azure resources
data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "default" {
  count    = local.existing_resource_group ? 0 : 1
  name     = var.name
  location = local.region
}

resource "azurerm_virtual_network" "default" {
  name                = format("%s-ars-vnet", var.name)
  address_space       = [var.cidr]
  resource_group_name = local.resource_group_name
  location            = local.region
}

#Azure Route Server resources
resource "azurerm_subnet" "ars" {
  name                 = "RouteServerSubnet"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = local.resource_group_name
  address_prefixes     = [cidrsubnet(var.cidr, 1, 1)]
}

resource "azurerm_public_ip" "ars" {
  name                = format("%s-ars-pip", var.name)
  resource_group_name = local.resource_group_name
  location            = local.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "default" {
  name                             = format("%s-ars", var.name)
  resource_group_name              = local.resource_group_name
  location                         = local.region
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars.id
  subnet_id                        = azurerm_subnet.ars.id
  branch_to_branch_traffic_enabled = true
}

#VNG Resources
resource "azurerm_public_ip" "vng" {
  name                = format("%s-vng-pip", var.name)
  resource_group_name = local.resource_group_name
  location            = local.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "vng" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = local.resource_group_name
  address_prefixes     = [cidrsubnet(var.cidr, 1, 0)]
}

resource "azurerm_virtual_network_gateway" "default" {
  name                = format("%s-vng", var.name)
  location            = local.region
  resource_group_name = local.resource_group_name

  type = "ExpressRoute"
  sku  = var.vng_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vng.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng.id
  }
}

#Connectivity to Aviatrix transit
resource "azurerm_virtual_network_peering" "default-1" {
  name                      = format("%s-peertransittoars", var.name)
  resource_group_name       = local.transit_resource_group
  virtual_network_name      = local.transit_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.default.id
  use_remote_gateways       = true

  depends_on = [
    azurerm_virtual_network_gateway.default
  ]
}

resource "azurerm_virtual_network_peering" "default-2" {
  name                      = format("%s-peerarstotransit", var.name)
  resource_group_name       = local.resource_group_name
  virtual_network_name      = azurerm_virtual_network.default.name
  remote_virtual_network_id = local.transit_resource_group_id
  allow_gateway_transit     = true

  depends_on = [
    azurerm_virtual_network_gateway.default
  ]
}

resource "azurerm_route_server_bgp_connection" "transit_gw" {
  name            = format("%s-transit_gw", var.name)
  route_server_id = azurerm_route_server.default.id
  peer_asn        = local.transit_as_number
  peer_ip         = var.local_lan_ip
}

resource "azurerm_route_server_bgp_connection" "transit_hagw" {
  name            = format("%s-transit_hagw", var.name)
  route_server_id = azurerm_route_server.default.id
  peer_asn        = local.transit_as_number
  peer_ip         = var.backup_local_lan_ip
}

resource "aviatrix_transit_external_device_conn" "default" {
  vpc_id                   = local.transit_vnet_id
  connection_name          = format("%s-ars-bgp", var.name)
  gw_name                  = local.transit_gateway_name
  connection_type          = "bgp"
  tunnel_protocol          = "LAN"
  remote_vpc_name          = format("%s:%s:%s", azurerm_virtual_network.default.name, local.resource_group_name, data.azurerm_subscription.current.subscription_id)
  ha_enabled               = true
  bgp_local_as_num         = local.transit_as_number
  bgp_remote_as_num        = "65515"
  backup_bgp_remote_as_num = "65515"
  remote_lan_ip            = tolist(azurerm_route_server.default.virtual_router_ips)[0]
  backup_remote_lan_ip     = tolist(azurerm_route_server.default.virtual_router_ips)[1]
  # local_lan_ip              = var.local_lan_ip        #var.transit_gw_obj.bgp_lan_ip_list[0]
  # backup_local_lan_ip       = var.backup_local_lan_ip #var.transit_gw_obj.ha_bgp_lan_ip_list[0]
  enable_bgp_lan_activemesh = true
  manual_bgp_advertised_cidrs = var.avx_manual_bgp_advertised_cidrs

  depends_on = [
    azurerm_virtual_network_peering.default-1,
    azurerm_virtual_network_peering.default-2,
  ]
}

resource "aviatrix_segmentation_network_domain_association" "default" {
  count                = length(var.network_domain) > 0 ? 1 : 0 #Only create resource when attached and network_domain is set.
  transit_gateway_name = local.transit_gateway_name
  network_domain_name  = var.network_domain
  attachment_name      = aviatrix_transit_external_device_conn.default.connection_name
  depends_on           = [aviatrix_transit_external_device_conn.default] #Let's make sure this cannot create a race condition

  lifecycle {
    # Transit gateway must have segmentation enabled for network domain to be associated.
    precondition {
      condition     = local.segmentation_enabled
      error_message = "The transit gateway does not have segmentation enabled."
    }
  }
}
