#!/bin/bash

storageAccountName=$1
container='deployscripts'
if [ `az storage container exists --account-name $storageAccountName  -n $container -o tsv` = 'False' ] 
then 
    az storage container create -n $container --account-name $storageAccountName >> /dev/null
fi 

expirydate=`date -u --date '1 day' +'%Y-%m-%dT%H:%M:%SZ'`

saskey=`az storage container generate-sas --permissions rwl --expiry $expirydate  -n $container --account-name $storageAccountName  --https-only -o tsv`

url='https://'$storageAccountName'.blob.core.windows.net/'$container


az storage blob upload-batch --destination ${container} --source .. --pattern "[a-zA-Z]?*" --account-name $storageAccountName
echo "run the following before running any deploy scripts"
echo "   export SCRIPT_SASKEY=\"?$saskey\""
echo "   export SCRIPT_URL=\"$url\""

