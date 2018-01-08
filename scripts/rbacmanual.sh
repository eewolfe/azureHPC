#!/bin/bash

rg=$1
custsa=$2
vmssName=$3

subid=$(az account show --query "id" --out tsv)
spID=$(az resource list -n spimaster -g $rg --query [*].identity.principalId --out tsv)
echo $spID
az role assignment create --assignee $spID --role 'Owner' --scope '/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Compute/virtualMachineScaleSets/'$vmssName

az role assignment create --assignee $spID --role 'Owner' --scope '/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Storage/storageAccounts/'$custsa


