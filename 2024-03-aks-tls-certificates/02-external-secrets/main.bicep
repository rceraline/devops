param location string = resourceGroup().location
param tenantId string = subscription().tenantId

@description('Object ID of the current user.')
param currentUserObjectId string

param acrName string = 'cr${uniqueString(resourceGroup().id)}'
param kvName string = 'kv-${uniqueString(resourceGroup().id)}'

var clusterName = 'aks-01'
var vmSize = 'Standard_D2s_v3'

var acrPullRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var manageIdentityOperatorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
var kvCertificateOfficerRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
var kvCryptoOfficerRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '14b46e9e-c2b7-41b4-b07b-48a6ebf60603')
var kvCryptoUserRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424')
var kvSecretUserRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource vnet01 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet-01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-01'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-02'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    tenantId: tenantId
    accessPolicies: []
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: false
    enableRbacAuthorization: true
  }
}

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

resource workloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: 'id-workload-01'
  location: location
}

resource controlPlaneContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(controlPlaneIdentity.id, resourceGroup().id, contributorRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: controlPlaneIdentity.properties.principalId
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

resource controlPlaneCryptoUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(controlPlaneIdentity.id, kvCryptoUserRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvCryptoUserRoleDefinitionId
    principalId: controlPlaneIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource currentUserRoleAssignmentForAcr 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(currentUserObjectId, contributorRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

resource kubeletRoleAssignmentForAcr 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(kubeletIdentity.id, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: kubeletIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource currentUserRoleAssignmentForKeyVaultCertificateOfficer 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(currentUserObjectId, kvCertificateOfficerRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvCertificateOfficerRoleDefinitionId
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

resource currentUserRoleAssignmentForKeyVaultCryptoOfficer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(currentUserObjectId, kvCryptoOfficerRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvCryptoOfficerRoleDefinitionId
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

resource workloadIdentityRoleAssignmentForKeyVault 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(workloadIdentity.id, kvSecretUserRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvSecretUserRoleDefinitionId
    principalId: workloadIdentity.properties.principalId
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
    agentPoolProfiles: [
      {
        name: 'linux01'
        osDiskSizeGB: 0
        count: 1
        vmSize: vmSize
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet01.name, 'snet-02')
      }
    ]
    identityProfile: {
      kubeletidentity: {
        resourceId: kubeletIdentity.id
        clientId: kubeletIdentity.properties.clientId
        objectId: kubeletIdentity.properties.principalId
      }
    }
    networkProfile: {
      dnsServiceIP: '10.0.3.4'
      networkPlugin: 'azure'
      serviceCidr: '10.0.3.0/24'
    }
    addonProfiles: {}
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
  dependsOn: [
    controlPlaneContributorRoleAssignment
    controlPlaneIdentityOperatorRoleAssignment
    controlPlaneCryptoUserRoleAssignment
  ]
}

output acrUrl string = '${acr.name}.azurecr.io'
