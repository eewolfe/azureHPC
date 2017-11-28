#!/bin/bash

set -x 

az account set -s ""
az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/eewolfe/azureHPC/custom2/Compute-Grid-Infra/custom/custom-script.json --parameters @seisspace.param.json

