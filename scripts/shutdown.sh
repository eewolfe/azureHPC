#!/bin/bash

########################################
# $1 is the Resource Group
# $2 is the prefix for the VM Scale Set
########################################

set -x 

rg=$1

# DONT USE vmss scale --new-capacity 0 
# THIS WILL CAUSE THE VMs to lose any persistent data when the scale set is restarted

az vmss deallocate -g $rg -n BeeGFS --instance-ids "*" --no-wait
az vmss scale -g $rg -n $200 --new-capacity 0
az vm deallocate -g $rg -n $2master --no-wait

