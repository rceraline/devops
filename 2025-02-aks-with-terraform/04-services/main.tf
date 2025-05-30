## Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "premium"

  enable_rbac_authorization     = true
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-${var.key_vault_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.key_vault_name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.kv.id]
  }
}

## Container Registry
resource "azurerm_container_registry" "cr" {
  name                          = var.container_registry_name
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "cr" {
  name                = "pe-${var.container_registry_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-${var.container_registry_name}"
    private_connection_resource_id = azurerm_container_registry.cr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.container_registry_name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.cr.id]
  }
}

## Storage Account
resource "azurerm_storage_account" "st" {
  name                          = var.storage_account_name
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = false
  https_traffic_only_enabled    = true
}

resource "azurerm_private_endpoint" "st" {
  name                = "pe-${var.storage_account_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-${var.storage_account_name}"
    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.storage_account_name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.st.id]
  }
}
