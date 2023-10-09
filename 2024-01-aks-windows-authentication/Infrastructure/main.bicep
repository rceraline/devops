param location string = resourceGroup().location
param tenantId string = subscription().tenantId

@description('Admin user account for the DC.')
param username string = 'useradmin'

@description('Admin user account for the DC.')
@secure()
param password string

@description('Object ID of the current user.')
param currentUserObjectId string

param acrName string = 'cr${uniqueString(resourceGroup().id)}'
param kvName string = 'kv-${uniqueString(resourceGroup().id)}'

var dnsServerId = '10.0.1.4'
var azureDnsServer = '168.63.129.16'
var dnsServers = [ azureDnsServer, dnsServerId ]
var clusterName = 'aks-01'
var agentCount = 2
var vmSize = 'Standard_D4s_v3'

var acrPullRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var networkContributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var manageIdentityOperatorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
var manageIdentityContributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'e40ec5ca-96e0-45a2-b4ff-59039f2c2b59')
var kvSecretOfficerRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
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
    dhcpOptions: {
      dnsServers: dnsServers
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
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
    ]
  }
}

resource dcNetworkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'nic-dc-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: vnet01.properties.subnets[1].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: dnsServerId
        }
      }
    ]
  }
}

resource vm01NetworkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'nic-vm-01'
  location: location
  properties: {
    dnsSettings: {
      dnsServers: [
        dnsServerId
      ]
    }
    ipConfigurations: [
      {
        name: 'ipconfig-1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.5'
          subnet: {
            id: vnet01.properties.subnets[1].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource dc 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-dc-01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'vm-dc-01'
      adminUsername: username
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'disk-dc-01'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: dcNetworkInterface.id
        }
      ]
    }
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

resource dcScript 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: 'dc-script'
  location: location
  parent: dc
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      commandToExecute: 'powershell Install-WindowsFeature AD-Domain-Services -IncludeManagementTools; Install-ADDSForest -DomainName "mycompany.local" -DomainNetbiosName mycompany -InstallDNS -SafeModeAdministratorPassword $(ConvertTo-SecureString "${password}" -AsPlainText -Force) -Force'
    }
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
            id: vnet01.properties.subnets[0].id
          }
          publicIPAddress: {
            id: basIp.id
          }
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

resource vnetNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(controlPlaneIdentity.id, vnet01.id, networkContributorRoleDefinitionId)
  scope: vnet01
  properties: {
    roleDefinitionId: networkContributorRoleDefinitionId
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
  name: guid(currentUserObjectId, kvSecretOfficerRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvSecretOfficerRoleDefinitionId
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

resource kvRoleAssignmentForAks 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(kubeletIdentity.id, kvSecretUserRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvSecretUserRoleDefinitionId
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
      {
        name: 'win01'
        osDiskSizeGB: 0
        count: agentCount
        vmSize: vmSize
        osType: 'Windows'
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
    windowsProfile: {
      adminUsername: username
      adminPassword: password
      gmsaProfile: {
        enabled: true
      }
    }
  }
}

output acrUrl string = '${acr.name}.azurecr.io'
