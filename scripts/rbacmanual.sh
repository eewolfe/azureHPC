#!/bin/bash

rg=$1
vmssName=$2
masterName=$3

subid=$(az account show --query "id" --out tsv)
spID=$(az resource list -n $masterName -g $rg --query [*].identity.principalId --out tsv)
echo $spID
custsa=$(az group deployment show -n deploy-master -g $rg --query "properties.outputs.customerStorage.value" --out tsv)

az role assignment create --assignee $spID --role 'Owner' --scope '/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Compute/virtualMachineScaleSets/'$vmssName

az role assignment create --assignee $spID --role 'Owner' --scope '/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Storage/storageAccounts/'$custsa


