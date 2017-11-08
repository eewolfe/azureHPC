#!/bin/bash
RGNAME=`az group list --output table | grep '\-03' | cut -d' ' -f1`
az group deployment create -g $RGNAME -n deploymaster  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Lab/Compute-Grid-Infra/deploy-master.json  --parameters @master.param.json
az group deployment create -g $RGNAME -n deploynodes  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Lab/Compute-Grid-Infra/deploy-nodes.json  --parameters @nodes.param.json
