#!/bin/bash

rg=mzspi

./deploy.master.sh $rg
az group deployment show -n deploy-master -g $rg --query "properties.outputs"
custStorage=$(az group deployment show -n deploy-master -g $rg --query "properties.outputs.customerStorage.value" --out tsv)
hostname=$(az group deployment show -n deploy-master -g $rg --query "properties.outputs.masterFQDN.value" --out tsv)
# Get public IP
# Get customer storage account

./deploy.beegfs.sh $rg
az vm restart -g $rg -n spimaster
./deploy.nodes.sh $rg
./rbacmanual.sh $rg $custStorage
