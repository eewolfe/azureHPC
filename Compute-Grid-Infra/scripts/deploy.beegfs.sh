#!/bin/bash
set -x 

cat beegfs.param.json.tmpl >> beegfs.param.json

sed -i "s/spix/$1/g" beegfs.param.json
cat beegfs.param.json

az account set -s "Commercial-Chevron"
az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/eewolfe/azureHPC/custom2/Compute-Grid-Infra/BeeGFS/deploy-beegfs-vmss.json --parameters @beegfs.param.json

rm beegfs.param.json