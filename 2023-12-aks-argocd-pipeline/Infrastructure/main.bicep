param location string = resourceGroup().location

@description('Object ID of the current user.')
param currentUserObjectId string

@description('Admin user account.')
param username string = 'useradmin'

@description('Admin user account.')
@secure()
param password string

param acrName string = 'cr${uniqueString(resourceGroup().id)}'

var clusterName = 'aks-01'
var applicationGatewayName = 'agw-01'
var agwIpAddress = '10.0.0.4'

var vmSize = 'Standard_D4s_v3'

var acrPullRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
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

resource applicationGatewayRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(applicationGateway.id, contributorRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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
        name: 'snet-agw'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
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
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.10.0/24'
        }
      }
    ]
  }
}

resource basIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'ip-bas-01'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'bas-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ip-bas-01'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: basIp.id
          }
        }
      }
    ]
  }
}

resource vm01NetworkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'nic-vm-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-01')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource vm01 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'vm-01'
      adminUsername: username
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-22h2-ent'
        version: 'latest'
      }
      osDisk: {
        name: 'disk-vm-01'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm01NetworkInterface.id
        }
      ]
    }
  }
}

resource agwPublicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
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

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-agw')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'agw-public-ip'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: agwPublicIPAddress.id
          }
        }
      }
      {
        name: 'agw-private-ip'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: agwIpAddress
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-agw')
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
        name: 'backendpool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpsetting'
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
        name: 'listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'agw-private-ip')
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
        name: 'routingrule'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'backendpool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'httpsetting')
          }
        }
      }
    ]
    sku: {
      capacity: 1
      name: 'Standard_v2'
      tier: 'Standard_v2'
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
    identityProfile: {
      kubeletidentity: {
        resourceId: kubeletIdentity.id
        clientId: kubeletIdentity.properties.clientId
        objectId: kubeletIdentity.properties.principalId
      }
    }
    addonProfiles: {
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: applicationGateway.id
        }
      }
    }
    networkProfile: {
      dnsServiceIP: '10.0.3.4'
      networkPlugin: 'azure'
      serviceCidr: '10.0.3.0/24'
    }
    agentPoolProfiles: [
      {
        name: 'linux01'
        osDiskSizeGB: 0
        count: 1
        vmSize: 'Standard_D2s_v3'
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-02')
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'mycompany.com'
  location: 'global'
}

resource app01Record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: 'app-01'
  parent: privateDnsZone
  properties: {
    ttl: 30
    aRecords: [
      {
        ipv4Address: agwIpAddress
      }
    ]
  }
}

resource app01StagingRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: 'app-01-staging'
  parent: privateDnsZone
  properties: {
    ttl: 30
    aRecords: [
      {
        ipv4Address: agwIpAddress
      }
    ]
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-vnet-01'
  location: 'global'
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output acrUrl string = '${acr.name}.azurecr.io'
