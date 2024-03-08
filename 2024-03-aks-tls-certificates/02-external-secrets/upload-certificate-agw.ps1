$kvName = 'kv-punjt2filcllc'

az keyvault certificate create --vault-name $kvName `
    -n my-certificate `
    -p `@policy.json

az network application-gateway ssl-cert create --gateway-name agw-01 `
    --name my-certificate `
    --resource-group rg-tlscertificate-01 `
    --key-vault-secret-id "https://$kvName.vault.azure.net/secrets/my-certificate"