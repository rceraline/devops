resource "azurerm_container_registry" "cr" {
  name                          = "cr20240701"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "cr" {
  name                = "pe-cr20240701"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.utils_01.id

  private_service_connection {
    name                           = "psc-cr20240701"
    private_connection_resource_id = azurerm_container_registry.cr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "pdzg-cr20240701"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.cr.id]
  }
}

### Key vault

resource "azurerm_key_vault" "kv" {
  name                        = "kv-2024070102"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "premium"

  enable_rbac_authorization     = true
  public_network_access_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-${azurerm_key_vault.kv.name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.utils_01.id

  private_service_connection {
    name                           = "psc-${azurerm_key_vault.kv.name}"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdzg-${azurerm_key_vault.kv.name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.kv.id]
  }
}

data "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "keyvault_administrator" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
