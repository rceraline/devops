$resourceGroupName = 'rg-tfstate-cac'
$storageAccountName = 'satfstatecac20230510'
$location = 'canadacentral'

az group create --location $location --name $resourceGroupName
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS
az storage container create --name state --account-name $storageAccountName
az storage account blob-service-properties update --account-name $storageAccountName --enable-change-feed true --enable-versioning true