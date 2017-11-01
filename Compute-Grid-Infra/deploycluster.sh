#!/bin/bash
az group deployment create -g $1 -n deploymaster  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Lab/Compute-Grid-Infra/deploy-master.json  --parameters @master.param.json
az group deployment create -g $1 -n deploynodes  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Lab/Compute-Grid-Infra/deploy-nodes.json  --parameters @nodes.param.json
