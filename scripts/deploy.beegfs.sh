#!/bin/bash

set -x 

az account set -s ""
az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/eewolfe/azureHPC/master/BeeGFS/deploy-beegfs-vmss.json --parameters @beegfs.param.json --parameters _artifactsLocation='https://raw.githubusercontent.com/eewolfe/azureHPC/master/'
