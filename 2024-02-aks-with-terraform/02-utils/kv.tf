data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-20240207"
  location                    = data.azurerm_resource_group.rg_01.location
  resource_group_name         = data.azurerm_resource_group.rg_01.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "premium"

  enable_rbac_authorization     = true
  public_network_access_enabled = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-20240207"
  location            = data.azurerm_resource_group.rg_01.location
  resource_group_name = data.azurerm_resource_group.rg_01.name
  subnet_id           = data.azurerm_subnet.utils_01.id

  private_service_connection {
    name                           = "psc-kv-20240207"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdzg-kv-20240207"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.kv.id]
  }
}

data "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}

resource "azurerm_role_assignment" "certificate_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = var.key_vault_certificate_officer_id
}
