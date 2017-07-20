az group create -n ready1 -l southcentralus
az group deployment create -g ready1 -n labdeployment  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Ready/Compute-Grid-Infra/deploy-master.json  --parameters @param.json
az group deployment create -g ready1 -n labdeployment  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Ready/Compute-Grid-Infra/deploy-nodes.json  --parameters @param.json
