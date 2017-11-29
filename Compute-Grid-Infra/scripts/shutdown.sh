#!/bin/bash

set -x 

rg=$1
az vmss scale -g $rg -n BeeGFS --new-capacity 0 --no-wait
az vmss scale -g $rg -n spi00 --new-capacity 0 --no-wait
az vm stop -g $rg -n spimaster --no-wait


