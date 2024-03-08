param location string = resourceGroup().location
param tenantId string = subscription().tenantId

@description('Object ID of the current user.')
param currentUserObjectId string

param kvName string = 'kv-${uniqueString(resourceGroup().id)}'
var aksKMSKeyName = 'aks-kms-key-01'

var kvCryptoOfficerRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '14b46e9e-c2b7-41b4-b07b-48a6ebf60603')

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

resource currentUserRoleAssignmentForKeyVaultCryptoOfficer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(currentUserObjectId, kvCryptoOfficerRoleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: kvCryptoOfficerRoleDefinitionId
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

resource aksKMSKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  name: aksKMSKeyName
  parent: kv
  properties: {
    keySize: 2048
    kty: 'RSA'
    keyOps: [
      'decrypt'
      'encrypt'
    ]
  }
  dependsOn: [
    currentUserRoleAssignmentForKeyVaultCryptoOfficer
  ]
}
