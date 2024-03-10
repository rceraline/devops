$clusterName = 'aks-01'
$resourceGroupName = 'rg-tlscertificate-01'
$identityName = 'id-workload-01'
$federatedIdentityName = 'fid-workload-01'
$namespace = 'default'
$serviceAccountName = 'sa-workload-01'

az aks get-credentials -n $clusterName -g $resourceGroupName

$clientId = $(az identity show --resource-group $resourceGroupName --name $identityName --query 'clientId' -otsv)
$oidcIssuer = $(az aks show -n $clusterName -g $resourceGroupName --query "oidcIssuerProfile.issuerUrl" -otsv)

$serviceAccount = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $clientId
  name: $serviceAccountName
  namespace: $namespace
"@

$serviceAccount | kubectl apply -f -

az identity federated-credential create `
    --name $federatedIdentityName `
    --identity-name $identityName `
    --resource-group $resourceGroupName `
    --issuer $oidcIssuer `
    --subject "system:serviceaccount:${namespace}:${serviceAccountName}" `
    --audience api://AzureADTokenExchange