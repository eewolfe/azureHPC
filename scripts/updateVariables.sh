#!/bin/bash

set -x 

# General script variables

# Master Node

export vmPrefix=''
export newOrExisting='existing'
export resourceGroup=''
export virtualNetworkName=''
export sshKeyData=''

# Beegfs

# SeisSpace
export storageAccount=''
export storageKey=''

# Nodes
export vmSSprefix='node'

# User nodes
export vmNamePrefix='nav'


# param.json update functions

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
  sed -i "s|VMPC|$vmSSPrefix|"         ./nodes.param.json

}

update_usernode () {

  sed -i "s|RGP|$resourceGroup|"       ./usernode.param.json
  sed -i "s|VNN|$virtualNetworkName|"  ./usernode.param.json
  sed -i "s|ssh-rsa|$sshKeyData|"      ./usernode.param.json
  sed -i "s|VMP|$vmPrefix|"            ./usernode.param.json
  sed -i "s|VMPN|$vmNamePrefix|"       ./usernode.param.json

}

update_master
update_beegfs
update_seisspace
update_nodes

exit 0
