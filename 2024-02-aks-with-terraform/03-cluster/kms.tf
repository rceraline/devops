data "azurerm_client_config" "current" {
}

resource "azurerm_role_assignment" "crypto_officer" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_key" "kms" {
  name         = "generated-kms"
  key_vault_id = data.azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt"
  ]
}
