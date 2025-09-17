@description('Required. Name of the storage account (lowercase).')
param storageAccountName string

@description('Optional. Location for the storage account. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional. Tags to apply to the storage account.')
param tags object = {}

@allowed(['Cool', 'Hot', 'Premium', 'Cold'])
@description('Optional. Specifies the access tier for BlobStorage, valid values: Cool, Hot, Premium, Cold.')
param accessTier string = 'Hot'

@description('Optional. Minimum permitted TLS version for requests to the storage account.')
param minimumTlsVersion string = 'TLS1_2'

@description('Optional. Enforces HTTPS only traffic when set to true.')
param supportsHttpsTrafficOnly bool = true

@description('Optional. Storage account SKU (limited to values supported by AVM module version 0.21.0).')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_GRS'

@description('Optional. Role assignments for the storage account (array of objects with principalId, roleDefinitionIdOrName, principalType).')
param roleAssignments array = []

import { privateEndpointMultiServiceType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param privateEndpoints privateEndpointMultiServiceType[]?

// @description('Required. Array of AVM private DNS zone module outputs used to associate private endpoints.')
// param avmPrivateDnsZones array
// @description('Required. Object containing keys used to index into avmPrivateDnsZones outputs (e.g. storageBlob, storageQueue).')
// param dnsZoneIndex object
@description('Optional. If true, disables public network access and provisions private endpoints for blob and queue services.')
param enablePrivateNetworking bool = false

@description('Optional. Controls whether AVM telemetry is enabled for this deployment.')
param enableTelemetry bool = true

var kind = 'StorageV2'

module avmStorageAccount 'br/public:avm/res/storage/storage-account:0.26.2' = {
  name: take('avm.res.storage.storage-account.${storageAccountName}', 64)
  params: {
    name: storageAccountName
    location: location
    managedIdentities: { systemAssigned: true }
    minimumTlsVersion: minimumTlsVersion
    enableTelemetry: enableTelemetry
    tags: tags
    accessTier: accessTier
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    skuName: skuName
    kind: kind
    // Use only user-assigned identities
    roleAssignments: roleAssignments
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: enablePrivateNetworking ? 'Deny' : 'Allow'
    }
    allowBlobPublicAccess: enablePrivateNetworking ? true : false
    publicNetworkAccess: enablePrivateNetworking ? 'Disabled' : 'Enabled'
    // Private endpoints for blob and queue
    privateEndpoints: privateEndpoints
    blobServices: {
      corsRules: []
      deleteRetentionPolicyEnabled: true
      deleteRetentionPolicyDays: 7
      containerDeleteRetentionPolicyEnabled: true
      containerDeleteRetentionPolicyDays: 7
      containers: [
        {
          name: 'data'
          publicAccess: 'None'
          denyEncryptionScopeOverride: false
          defaultEncryptionScope: '$account-encryption-key'
        }
      ]
    }
  }
}

@description('The name of the storage account created.')
output name string = avmStorageAccount.outputs.name

@description('The resource ID of the storage account created.')
output resourceId string = avmStorageAccount.outputs.resourceId

@description('The primary access key for the storage account created.')
@secure()
output primaryAccessKey string = avmStorageAccount.outputs.primaryAccessKey
