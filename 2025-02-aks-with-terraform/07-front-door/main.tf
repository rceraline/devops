
resource "random_id" "front_door_endpoint_name" {
  byte_length = 8
}

locals {
  front_door_profile_name      = "frontdoor-01"
  front_door_endpoint_name     = "afd-${lower(random_id.front_door_endpoint_name.hex)}"
  front_door_origin_group_name = "origin-group-01"
  front_door_origin_name       = "origin-aks-lb-01"
  front_door_route_name        = "route-01"
}

resource "azurerm_cdn_frontdoor_profile" "front_door" {
  name                = local.front_door_profile_name
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door.id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = local.front_door_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "aks_load_balancer" {
  name                          = local.front_door_origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = data.azurerm_lb.aks.private_ip_address
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000

  private_link {
    request_message        = "Request access for Private Link Origin CDN Frontdoor"
    location               = data.azurerm_resource_group.rg.location
    private_link_target_id = azurerm_private_link_service.load_balancer.id
  }
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = local.front_door_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.aks_load_balancer.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}

resource "azurerm_private_link_service" "load_balancer" {
  name                = "pls-${var.aks_load_balancer_name}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  visibility_subscription_ids                 = [data.azurerm_client_config.current.subscription_id]
  load_balancer_frontend_ip_configuration_ids = [data.azurerm_lb.aks.frontend_ip_configuration.0.id]

  nat_ip_configuration {
    name      = "primary"
    subnet_id = data.azurerm_subnet.load_balancer.id
    primary   = true
  }
}
