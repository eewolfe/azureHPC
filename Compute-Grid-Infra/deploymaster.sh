az group create -n ready -l southcentralus
az group deployment create -g ready -n labdeployment  --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/Ready/Compute-Grid-Infra/deploy-master.json  --parameters @master.param.json
