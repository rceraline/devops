$kvName = 'kv-punjt2filcllc'
$keyName = 'aks-kms-key-01'
$clusterName = 'aks-01'
$resourceGroupName = 'rg-tlscertificate-01'

## Create a key in Key Vault. For some reason I wasn't able to do it with Bicep.
az keyvault key create --kty RSA `
                    --name $keyName `
                    --ops decrypt encrypt `
                    --size 2048 `
                    --vault-name $kvName
                    
$keyId = $(az keyvault key show --name $keyName --vault-name $kvName --query 'key.kid' -o tsv)

## Update cluster to enable KMS
az aks update --name $clusterName `
    --resource-group $resourceGroupName `
    --enable-azure-keyvault-kms `
    --azure-keyvault-kms-key-vault-network-access "Public" `
    --azure-keyvault-kms-key-id $keyId

## Create self signed certificate
az keyvault certificate create --vault-name $kvName `
    -n my-certificate `
    -p `@policy.json