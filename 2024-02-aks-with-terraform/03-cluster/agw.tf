data "azurerm_subnet" "agw_01" {
  name                 = "snet-agw-01"
  virtual_network_name = "vnet-aks-01"
  resource_group_name  = data.azurerm_resource_group.rg_01.name
}


resource "azurerm_public_ip" "pip_02" {
  name                = "pip-02"
  resource_group_name = data.azurerm_resource_group.rg_01.name
  location            = data.azurerm_resource_group.rg_01.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name              = "agw-beap"
  frontend_port_name                     = "agw-feport"
  frontend_ip_configuration_name         = "agw-feip"
  frontend_ip_private_configuration_name = "agw-pv-feip"
  http_setting_name                      = "agw-be-htst"
  listener_name                          = "agw-httplstn"
  request_routing_rule_name              = "agw-rqrt"
  redirect_configuration_name            = "agw-rdrcfg"
}

resource "azurerm_application_gateway" "agw_01" {
  name                = "agw-01"
  resource_group_name = data.azurerm_resource_group.rg_01.name
  location            = data.azurerm_resource_group.rg_01.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gic-01"
    subnet_id = data.azurerm_subnet.agw_01.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip_02.id
  }

  frontend_ip_configuration {
    name                          = local.frontend_ip_private_configuration_name
    subnet_id                     = data.azurerm_subnet.agw_01.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.4"
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agw_01.id]
  }

  ssl_certificate {
    name                = "cert-website-com"
    key_vault_secret_id = "https://kv-20240207.vault.azure.net/secrets/cert-website-com"
  }

  lifecycle {
    ignore_changes = [
      tags,
      frontend_port,
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      redirect_configuration,
      request_routing_rule
    ]
  }

  depends_on = [azurerm_role_assignment.agw]
}

resource "azurerm_user_assigned_identity" "agw_01" {
  location            = data.azurerm_resource_group.rg_01.location
  name                = "id-agw-01"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}

resource "azurerm_role_assignment" "agw" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agw_01.principal_id
}

data "azurerm_key_vault" "kv" {
  name                = "kv-20240207"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}
