az group create -n ready1 -l southcentralus
az group deployment create -g ready1 -n deploymaster  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Ready/Compute-Grid-Infra/deploy-master.json  --parameters @master.param.json
az group deployment create -g ready1 -n deploynodes  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Ready/Compute-Grid-Infra/deploy-nodes.json  --parameters @nodes.param.json
