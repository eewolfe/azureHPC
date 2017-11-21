#!/bin/bash
set -x 

cat nodes.param.json.tmpl >> nodes.param.json

sed -i "s/spix/$1/g" nodes.param.json
cat nodes.param.json

az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/custom2/Compute-Grid-Infra/deploy-nodes.json --parameters @nodes.param.json

rm nodes.param.json

