#!/bin/bash

set -x 

# General script variables

export subscription='SBS'
export vmPrefix='cvx'
export newOrExisting='new'
export resourceGroup=$1
export virtualNetworkName='VNN'
export sshKeyData='ssh-rsa'

# Beegfs

# SeisSpace
export storageAccount='storeAcct'
export storageKey='storeKey'

# Nodes
export vmSSPrefix='node'

# User nodes
export vmNamePrefix='nav'


# param.json update functions

update_master () {

  sed -i "s"|SBS|$subscription|"       ./master.param.json
  sed -i "s|VMP|$vmPrefix|"            ./master.param.json
  sed -i "s|existing|$newOrExisting|"  ./master.param.json
  sed -i "s|RGP|$resourceGroup|"       ./master.param.json
  sed -i "s|VNN|$virtualNetworkName|"  ./master.param.json
  sed -i "s|ssh-rsa|$sshKeyData|"      ./master.param.json
  sed -i "s|VMP|$vmPrefix|"            ./master.param.json
  sed -i "s|VMP|$vmPrefix|"            ./deploy.master.sh

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
  sed -i "s|VNODE|$vmSSPrefix|"        ./nodes.param.json

}

update_usernode () {

  sed -i "s|RGP|$resourceGroup|"       ./usernode.param.json
  sed -i "s|VNN|$virtualNetworkName|"  ./usernode.param.json
  sed -i "s|ssh-rsa|$sshKeyData|"      ./usernode.param.json
  sed -i "s|VMP|$vmPrefix|"            ./usernode.param.json
  sed -i "s|VUSER|$vmNamePrefix|"      ./usernode.param.json

}

update_deploy_all() {

 sed -i "s|VMP|$vmPrefix|"            ./deploy.all.sh

}

env 

update_master
update_beegfs
update_seisspace
update_nodes
update_usernode
update_deploy_all

exit 0
