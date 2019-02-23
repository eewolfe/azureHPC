#!/bin/bash

set -x

#INPUT
rg=$1
vmssName=node00
masterName=VMPmaster

./deploy.master.sh $rg

az group deployment show -n $masterName -g $rg --query "properties.outputs"
custStorage=$(az group deployment show -n $masterName -g $rg --query "properties.outputs.customerStorage.value" --out tsv)
hostname=$(az group deployment show -n $masterName -g $rg --query "properties.outputs.masterFQDN.value" --out tsv)
# Get public IP
# Get customer storage account

./deploy.beegfs.sh $rg
az vm restart -g $rg -n $masterName

systemctl start beegfs-admon.service
systemctl start beegfs-helperd.service
systemctl start beegfs-client.service
systemctl status beegfs-client.service

./deploy.seisspace.sh $rg

./deploy.nodes.sh $rg
#./rbacmanual.sh $rg $vmssName $masterName
