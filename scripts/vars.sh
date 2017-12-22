Subscription='FlatGatherers'
# Master
masterRG='spi1'
vmPrefix=''
sharedStorage='beegfs'
dataDiskSize='P10'
scheduler='pbspro'
masterImage='RHEL_7.2'
masterVMsku='Standard_DS5_v2' #VMsku
numberofusers='5'
RGvnetName=$masterRG
vnetName='vnet-grid'
networkDetails = \''{"newOrExisting":"new", "resourceGroup": "'"$masterRG"'", "", "virtualNetworkName": "'"$vnetName"'", "addressPrefix": "10.127.90.0/23", "computeSubnetPrefix": "10.127.90.0/24", "storageSubnetPrefix": "10.127.91.0/25", "infraSubnetPrefix": "10.127.91.128/26", "appGatewaySubnetPrefix": "10.127.91.192/27", "gatewaySubnetPrefix": "10.127.91.224/27" }'\'
adminUserName='centos'
adminPassword=''
sshKeyData=''

# BeeGFS
VMsku='Standard_DS3_v2'
nodeCount=3
storageDiskSize='P10'
nbStorageDisks=3
masterName=$vmPrefixmaster

# Compute Nodes

VMsku='Standard_DS4_v2'
vmSSPrefix='cn'
computeNodeImage='RHEL_7.2'
numberOfVMSS=1
instanceCountPerVMSS=4
numberofusers=5

# Role Based Access

# User Nodes

VMsku='Standard_DS4_v2'
vmNamePrefix='nav'
computeNodeImage='RHEL_7.2'
instanceCount=1