#!/bin/bash

set -x 

rg=$1

az vmss start -g $rg -n BeeGFS --instance-ids "*" 
az vm   start -g $rg -n $2master
az vmss scale -g $rg -n $200 --new-capacity $3 --no-wait
