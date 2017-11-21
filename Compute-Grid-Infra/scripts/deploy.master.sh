#!/bin/bash
set -x 

az group create -n $1 -l southcentralus
az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/custom2/Compute-Grid-Infra/deploy-master.json --parameters @master.param.json

