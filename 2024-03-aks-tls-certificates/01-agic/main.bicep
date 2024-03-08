param location string = resourceGroup().location
param tenantId string = subscription().tenantId

@description('Object ID of the current user.')
param currentUserObjectId string

param acrName string = 'cr${uniqueString(resourceGroup().id)}'
param kvName string = 'kv-${uniqueString(resourceGroup().id)}'

var clusterName = 'aks-01'
var vmSize = 'Standard_D2s_v3'
var applicationGatewayName = 'agw-01'
var zoneName = 'mywebsite.local'

var acrPullRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var manageIdentityOperatorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
var kvCertificateOfficerRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
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

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
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

resource applicationGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: 'id-agw-01'
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

resource acrRoleAssignmentForUser 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(currentUserObjectId, contributorRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

resource acrRoleAssignmentForKubelet 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(kubeletIdentity.id, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: kubeletIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kvRoleAssignmentForUser 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(currentUserObjectId, kvCertificateOfficerRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvCertificateOfficerRoleDefinitionId
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

resource kvRoleAssignmentForApplicationGateway 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(applicationGatewayIdentity.id, kvSecretUserRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvSecretUserRoleDefinitionId
    principalId: applicationGatewayIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource applicationGatewayRoleAssignmentForAgic 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(aks.id, 'agic', contributorRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-01'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: applicationGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${applicationGatewayIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }

    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet01.name, 'snet-01')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPAddress.name)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'myBackendPool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'myHTTPSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'myListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'myRoutingRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'myListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'myBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'myHTTPSetting')
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
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
    addonProfiles: {
      ingressApplicationGateway: {
        config: {
          applicationGatewayId: applicationGateway.id
        }
        enabled: true
      }
    }
  }
  dependsOn: [
    controlPlaneContributorRoleAssignment
    controlPlaneIdentityOperatorRoleAssignment
  ]
}

output acrUrl string = '${acr.name}.azurecr.io'
