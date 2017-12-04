#!/bin/bash

set -x 

rg=$1
az vmss start  -g $rg -n BeeGFS --instance-ids * --no-wait
az vmss scale -g $rg -n spi00 --new-capacity 2 --no-wait
az vm start -g $rg -n spimaster --no-wait


