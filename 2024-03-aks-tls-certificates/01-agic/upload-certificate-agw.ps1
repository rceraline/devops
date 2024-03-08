az network application-gateway ssl-cert create --gateway-name agw-01 `
    --name my-certificate `
    --resource-group rg-tlscertificate-01 `
    --key-vault-secret-id https://kv-punjt2filcllc.vault.azure.net/secrets/my-certificate