az group create ready southcentralus
az group deployment create ready labdeployment  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Ready/Compute-Grid-Infra/deploy-master.json  --parameters @master.param.json
