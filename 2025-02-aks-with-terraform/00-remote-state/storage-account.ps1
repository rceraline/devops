$resourceGroupName = 'rg-tfstate-cac'
$location = 'canadacentral'
$storageAccountName = 'sttfstatecac20250502'
$containerName = 'state'

az group create --location $location --name $resourceGroupName
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS
az storage container create --name $containerName --account-name $storageAccountName
az storage account blob-service-properties update --account-name $storageAccountName --enable-change-feed --enable-versioning true