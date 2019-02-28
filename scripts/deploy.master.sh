#!/bin/bash

set -x 

if [ -z $SCRIPT_SASKEY ]; then
    SCRIPT_SASKEY=""
fi
if [ -z $SCRIPT_URL ]; then
    SCRIPT_URL='https://raw.githubusercontent.com/eewolfe/azureHPC/master'
fi

templateuri=$SCRIPT_URL'/Master/deploy-master.json'$SCRIPT_SASKEY
az account set --subscription "SBS"
az group create -g $1 -l southcentralus 
az group deployment create -n VMPmaster -g $1 --template-uri "$templateuri" --parameters @master.param.json --parameters _artifactsLocation="$SCRIPT_URL/" _artifactsLocationSasToken="$SCRIPT_SASKEY"
