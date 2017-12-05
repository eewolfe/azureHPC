#!/bin/bash

set -x 


az group deployment create -g $1 --template-file ../autoscaling/managed-service-identity.json --parameters @rbac.param.json --parameters _artifactsLocation='https://raw.githubusercontent.com/eewolfe/azureHPC/custom2/Compute-Grid-Infra/autoscaling'
