
# Master
vmPrefix=''
sharedStorage='beegfs'
dataDiskSize='P10'
scheduler='pbspro'
masterImage='RHEL_7.2'
masterVMsku='Standard_DS5_v2' #VMsku
numberofusers='5'
networkDetails=\''{"hostname": "localhost", "outdir": "'"$OUTDIR"'", "port": 20400, "size": 100000}'\'
networkDetails = \''{"newOrExisting":"new", "resourceGroup": "", "", "virtualNetworkName": "", "addressPrefix": "10.127.90.0/23", "computeSubnetPrefix": "10.127.90.0/24", "storageSubnetPrefix": "10.127.91.0/25", "infraSubnetPrefix": "10.127.91.128/26", "appGatewaySubnetPrefix": "10.127.91.192/27", "gatewaySubnetPrefix": "10.127.91.224/27" }'\'
adminUserName='centos'
adminPassword=''
sshKeyData=''

# BeeGFS
VMsku='Standard_DS3_v2'
nodeCount=3
storageDiskSize='P10'
nbStorageDisks=3
RGvnetName=
vnetName=

masterName=$vmPrefixmaster

# Compute Nodes

    "VMsku": { "value": "Standard_DS4_v2" },
    "vmSSPrefix": { "value": "" },
    "computeNodeImage": { "value": "RHEL_7.2" },
    "numberOfVMSS": { "value": 1 },
   
    "instanceCountPerVMSS": { "value": 4 },
   

    "numberofusers": { "value": "5" }

# Role Based Access

# User Nodes

    "VMsku": { "value": "Standard_DS4_v2" },
    "vmNamePrefix": { "value": "nav" },
    "computeNodeImage": { "value": "RHEL_7.2" },
    "instanceCount": { "value": 1 },

  }