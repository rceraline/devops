param location string = resourceGroup().location

@description('Object ID of the current user.')
param currentUserObjectId string

@description('Object ID of the Azure DevOps service principal.')
param azureDevOpsObjectId string

param acrName string = 'cr${uniqueString(resourceGroup().id)}'

var clusterName = 'aks-01'

var acrPullRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var acrPushRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var manageIdentityOperatorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
var manageIdentityContributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'e40ec5ca-96e0-45a2-b4ff-59039f2c2b59')

resource acr 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
}

resource controlPlaneIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: 'id-control-plane-01'
  location: location
}

resource kubeletIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: 'id-kubelet-01'
  location: location
}

// resource acrRoleAssignmentForUser 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
//   name: guid(currentUserObjectId, contributorRoleDefinitionId)
//   scope: acr
//   properties: {
//     roleDefinitionId: contributorRoleDefinitionId
//     principalId: currentUserObjectId
//     principalType: 'User'
//   }
// }

resource acrRoleAssignmentForKubelet 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(kubeletIdentity.id, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: kubeletIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource acrRoleAssignmentForAzureDevOps 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(azureDevOpsObjectId, acrPushRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPushRoleDefinitionId
    principalId: azureDevOpsObjectId
    principalType: 'ServicePrincipal'
  }
}

resource controlPlaneIdentityOperatorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(controlPlaneIdentity.id, manageIdentityOperatorRoleDefinitionId)
  scope: kubeletIdentity
  properties: {
    roleDefinitionId: manageIdentityOperatorRoleDefinitionId
    principalId: controlPlaneIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource controlPlaneIdentityContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(controlPlaneIdentity.id, manageIdentityContributorRoleDefinitionId)
  scope: kubeletIdentity
  properties: {
    roleDefinitionId: manageIdentityContributorRoleDefinitionId
    principalId: controlPlaneIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-06-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${controlPlaneIdentity.id}': {}
    }
  }
  properties: {
    dnsPrefix: clusterName
    identityProfile: {
      kubeletidentity: {
        resourceId: kubeletIdentity.id
        clientId: kubeletIdentity.properties.clientId
        objectId: kubeletIdentity.properties.principalId
      }
    }
    agentPoolProfiles: [
      {
        name: 'linux01'
        osDiskSizeGB: 0
        count: 1
        vmSize: 'Standard_D2s_v3'
        osType: 'Linux'
        mode: 'System'
      }
    ]
  }
}

output acrUrl string = '${acr.name}.azurecr.io'
