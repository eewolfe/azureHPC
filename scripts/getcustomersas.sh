#!/bin/bash

rg=$1
storageAccountName=$2
storageKey=$3
container='upload'


az storage container create -n $container --account-name $storageAccountName 

expirydate=`date -u --date '30 day' +'%Y-%m-%dT%H:%M:%SZ'`

saskey=`az storage container generate-sas --permissions rwl --expiry $expirydate  -n $container --account-name $storageAccountName  --https-only -o tsv`

az storage container show -n $container --account-name $storageAccountName -o tsv
url='https://'$storageAccountName'.blob.core.windows.net/'$container'?'$saskey
echo 'SAS KEY: '$saskey
echo 'URL: '$url
