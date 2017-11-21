#!/bin/bash
set -x 

az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/grandparoach/azure-hpc/custom2/Compute-Grid-Infra/custom/custom-script.json --parameters @seisspace.param.json

