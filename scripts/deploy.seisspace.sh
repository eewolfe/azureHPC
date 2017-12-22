#!/bin/bash

set -x 

az account set -s "Commercial-Chevron"

if [ -z $SCRIPT_SASKEY ]; then
    SCRIPT_SASKEY=""
fi
if [ -z $SCRIPT_URL ]; then
    SCRIPT_URL='https://raw.githubusercontent.com/eewolfe/azureHPC/master'
fi

templateuri=$SCRIPT_URL'/custom/custom-script.json'$SCRIPT_SASKEY

az group deployment create -g $1 --template-uri "$templateuri" --parameters @seisspace.param.json
