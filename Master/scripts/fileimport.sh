#!/bin/bash

# Get all containers in account

az login msi
az storage blob upload -n AzureHPC.zip -c $managedappcontainer --account-name $storageAccountName --account-key $storageKey -f ../../$zipfile



#Generate SAS key for managed app definition to securely access zip file for one day

expirydate=`date -u --date '14 day' +'%Y-%m-%dT%H:%M:%SZ'`

saskey=`az storage blob generate-sas --permissions r --expiry $expirydate  -n $zipfile -c $managedappcontainer --account-name $storageAccountName --account-key $storageKey -o tsv`

