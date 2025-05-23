targetScope = 'subscription'

/////////////////////////////////////////////////////////
///////////////////////Parameters///////////////////////
///////////////////////////////////////////////////////

@description('Name for the Resource Group to house K8s Components')
param k8sResourceGroupName string

@description('Kubernetes Cluster Name')
param k8sClusterName string

@description('Azure Container Registry Name')
@minLength(5)
@maxLength(50)
param acrName string

@description('Deployment Location')
param location string

@description('Object ID of the Workload Identity to assign Kubernetes Roles')
param workloadIdentityObjectID string


/////////////////////////////////////////////////////////
///////////////////////Resources////////////////////////
///////////////////////////////////////////////////////

@description('Deploys the Resource Group to house all the resources')
module k8sResourceGroup 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'resourceGroupDeployment'
  params: {
    name: k8sResourceGroupName
    location: location
  }
}

@description('Deploys the ACR to store the built docker image')
module registry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: 'registryDeployment'
  scope: resourceGroup(subscription().subscriptionId, k8sResourceGroupName)
  params: {
    name: acrName
    acrSku: 'Basic'
    location: location
    roleAssignments: [
      {
        // This allows the Kubernetes Cluster to Pull the Container Image and Deploy it
        principalId: managedCluster.outputs.kubeletIdentityObjectId 
        roleDefinitionIdOrName: 'AcrPull'
      }
    ]
  }
}

@description('Deploys the AKS Cluster')
module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.9.0' = {
  name: 'managedClusterDeployment'
  scope: resourceGroup(subscription().subscriptionId, k8sResourceGroupName)
  params: {
    name: k8sClusterName
    location: location
    
    primaryAgentPoolProfiles: [
      {
        count: 1
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_B2ms'
      }
    ]
    aadProfile: {
      aadProfileEnableAzureRBAC: true
      aadProfileManaged: true
    }
    disableLocalAccounts: false
    managedIdentities: {
      systemAssigned: true
    }
    networkPlugin: 'kubenet'
    skuTier: 'Free'
    publicNetworkAccess: 'Enabled' 
    roleAssignments: [
      {
        //Gives our Workload Identity sufficent permissions to deploy to the cluster
        principalId: workloadIdentityObjectID
        roleDefinitionIdOrName: 'Azure Kubernetes Service Cluster Admin Role'
      }
    ]
  }
  dependsOn: [
    k8sResourceGroup
  ]
}
