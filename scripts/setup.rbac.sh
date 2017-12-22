#!/bin/bash

set -x 

if [ -z $sas ]; then
    sas=""
fi

az group deployment create -g $1 --template-file ../autoscaling/managed-service-identity.json --parameters @rbac.param.json --parameters _artifactsLocation='https://raw.githubusercontent.com/eewolfe/azureHPC/master/autoscaling' _artifactsLocationSasToken='${sas}'
