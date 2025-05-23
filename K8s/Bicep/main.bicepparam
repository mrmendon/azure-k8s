using 'main.bicep'

param k8sClusterName = 'k8-uks-aspnet-prod'

param k8sResourceGroupName = 'rg-uks-k8s-prod'

param acrName = 'acraspnetuksk8sprod'

param location = 'uksouth'

//Copy from the created Workload Identity App registration once the Service Connection is created
param workloadIdentityObjectID = '000000000-0000-0000-0000-0000000000'
