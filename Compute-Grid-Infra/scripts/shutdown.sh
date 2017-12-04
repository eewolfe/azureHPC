#!/bin/bash

set -x 

rg=$1
# DONT USE vmss scale --new-capacity 0 
# THIS WILL CAUSE THE VMs to lose any persistent data when the scale set is restarted
#az vmss scale -g $rg -n BeeGFS --new-capacity 0 --no-wait
az vmss deallocate -n BeeGFS --instance-ids * --no-wait
az vmss scale -g $rg -n spi00 --new-capacity 0 --no-wait
az vm stop -g $rg -n spimaster --no-wait

