#!/bin/bash

set -x 

# General script variables

# Master Node

export vmPrefix='cvx'
export newOrExisting='existing'
export resourceGroup='cvx-shared-rg'
export virtualNetworkName='cvx-scus-vnet01'
export sshKeyData='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5LKolefwtgFfbrPCNfBEnVuJ8XSd3ArymEzcfJC/wd/4bwySJIHFVPFErd001WffGP73Yz/90NUXYeVVIFLcdGhPusr3RzNVKMAdxX0LDdMwk/XO/vu09jm9vSgQCO6xrzYF29bjVXKTlIHBV3LlZxly+6s0dFKyqNPGyg8PsDvYVs5SAGrJSWmEPNrkXgNF9p6ONqhS1LgiT4OawZaaz2Bdz/rLNh8lDz5U/B+ZsKKvtk0eRTcEIjkh7jnKDS+KrYBSEA/vZTJdjR3FpoyTDG5ti2AL7USAwqHweLCVXFPJ01DjoWzlCtSnavw3/LvZxJ3tTpYBeB17Iih7d3rmX'

# Beegfs

# SeisSpace
export storageAccount='seisspacefg'
export storageKey='6OWbnGTVwHJXXHm8U8Da4Hc3BLCIFjUWGbmZEfpYLAYvxCY51U5CRC3wSWQd2Zsxf9qDK4YGuuDNjAK+CMSSQQ=='

# Nodes
export vmSSprefix='node'


# Update master node deployment variables

update_master () {

  sed -i "s|VMP|$vmPrefix|"            ./master.param.json
  sed -i "s|existing|$newOrExisting|"  ./master.param.json
  sed -i "s|RGP|$resourceGroup|"       ./master.param.json
  sed -i "s|VNN|$virtualNetworkName|"  ./master.param.json
  sed -i "s|ssh-rsa|$sshKeyData|"      ./master.param.json

}

update_beegfs () {

  sed -i "s|RGP|$resourceGroup|"       ./beegfs.param.json
  sed -i "s|VNN|$virtualNetworkName|"  ./beegfs.param.json
  sed -i "s|ssh-rsa|$sshKeyData|"      ./beegfs.param.json
  sed -i "s|VMP|$vmPrefix|"            ./beegfs.param.json

}

update_seisspace () {

  sed -i "s|VMP|$vmPrefix|"          ./seisspace.param.json
  sed -i "s|StoreA|$storageAccount|" ./seisspace.param.json
  sed -i "s|StoreK|$storageKey|"     ./seisspace.param.json

}

update_nodes () {

  sed -i "s|RGP|$resourceGroup|"       ./nodes.param.json
  sed -i "s|VNN|$virtualNetworkName|"  ./nodes.param.json
  sed -i "s|ssh-rsa|$sshKeyData|"      ./nodes.param.json
  sed -i "s|VMP|$vmPrefix|"            ./nodes.param.json
  sed -i "s|VMPC|#vmSSprefix|"         ./nodes.param.json
}

#update_master
#update_beegfs
update_seisspace
#update_nodes

exit 0
