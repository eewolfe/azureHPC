#!/bin/bash

set -x 

az account set -s ""
az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/eewolfe/azureHPC/master/deploy-nodes.json --parameters @nodes.param.json --parameters _artifactsLocation='https://raw.githubusercontent.com/eewolfe/azureHPC/master/'
