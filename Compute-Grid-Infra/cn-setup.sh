!/bin/bash
export MOUNT_POINT=/mnt/azure

# Shares
SHARE_HOME=/shared/home
SHARE_SCRATCH=/shared/scratch
SHARE_APPS=/shared/Landmark
# SHARED=/shared
NFS_ON_MASTER=/shared/data
NFS_MOUNT=/shared/data

# User
HPC_USER=hpcuser
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007

#############################################################################
log()
{
	echo "$1"
}

usage() { echo "Usage: $0 [-a <azure storage account>] [-k <azure storage key>] [-m <masterName>] [-s <pbspro>] [-S <beegfs, nfsonmaster>] [-n <numberofusers>]" 1>&2; exit 1; }

while getopts :a:k:m:S:s:n: optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
    a)  # storage account
		export AZURE_STORAGE_ACCOUNT=${OPTARG}
		;;
    k)  # storage key
		export AZURE_STORAGE_ACCESS_KEY=${OPTARG}
		;;
    m)  # master name
		export MASTER_NAME=${OPTARG}
		;;
    S)  # Shared Storage (beegfs, nfsonmaster)
		export SHARED_STORAGE=${OPTARG}
		;;
    s)  # Scheduler (pbspro)
		export SCHEDULER=${OPTARG}
		;;
    n)  # number of users
		export numusers=${OPTARG}
		;;    
	*)
		usage
		;;
  esac
done


######################################################################
install_azure_cli()
{
	curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
	yum -y install nodejs

	[[ -z "$HOME" || ! -d "$HOME" ]] && { echo 'fixing $HOME'; HOME=/root; } 
	export HOME
	
	npm install -g azure-cli
	azure telemetry --disable
}

######################################################################
install_azure_files()
{
	log "install samba and cifs utils"
	yum -y install samba-client samba-common cifs-utils
	mkdir -p ${MOUNT_POINT}
	
	log "mount share"
	mount -t cifs //$AZURE_STORAGE_ACCOUNT.file.core.windows.net/lsf /mnt/azure -o vers=3.0,username=$AZURE_STORAGE_ACCOUNT,password=''${AZURE_STORAGE_ACCESS_KEY}'',dir_mode=0777,file_mode=0777
	echo //$AZURE_STORAGE_ACCOUNT.file.core.windows.net/lsf /mnt/azure cifs vers=3.0,username=$AZURE_STORAGE_ACCOUNT,password=''${AZURE_STORAGE_ACCESS_KEY}'',dir_mode=0777,file_mode=0777 >> /etc/fstab
	
}

install_lsf()
{
	log "install lsf"
	/apps/Azure/deployment.pex /apps/Azure/plays/setup_clients.yml
}

install_applications()
{
	log "install applications"		
	bash spi_p3_cn.sh ${numusers} 
}

mount_nfs()
{
	log "install NFS"

	yum -y install nfs-utils nfs-utils-lib
	
	mkdir -p /shared
	mkdir -p ${SHARE_SCRATCH}
	mkdir -p ${SHARE_APPS}
	mkdir -p ${SHARE_HOME}

	# mkdir -p ${SHARED}
	# mkdir -p ${NFS_MOUNT}

	log "mounting NFS on " ${MASTER_NAME}
	showmount -e ${MASTER_NAME}
	mount -t nfs ${MASTER_NAME}:${SHARE_SCRATCH} ${SHARE_SCRATCH}
	mount -t nfs ${MASTER_NAME}:${SHARE_APPS} ${SHARE_APPS}
	mount -t nfs ${MASTER_NAME}:${SHARE_HOME} ${SHARE_HOME}
    # mount -t nfs ${MASTER_NAME}:${SHARED} ${SHARED}
    # mount -t nfs ${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT}
	
	echo "${MASTER_NAME}:${SHARE_SCRATCH} ${SHARE_SCRATCH} nfs defaults,nofail  0 0" >> /etc/fstab
	echo "${MASTER_NAME}:${SHARE_APPS} ${SHARE_APPS} nfs defaults,nofail  0 0" >> /etc/fstab
	echo "${MASTER_NAME}:${SHARE_HOME} ${SHARE_HOME} nfs defaults,nofail  0 0" >> /etc/fstab	
	# echo "${MASTER_NAME}:${SHARED} ${SHARED} nfs defaults,nofail  0 0" >> /etc/fstab
	# echo "${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT} nfs defaults,nofail  0 0" >> /etc/fstab
}

install_beegfs_client()
{
	bash install_beegfs.sh ${MASTER_NAME} "client"
}

install_ganglia()
{
	bash install_ganglia.sh ${MASTER_NAME} "Cluster" 8649
}

install_pbspro()
{
	bash install_pbspro.sh ${MASTER_NAME}
}

#install the Linux Integration Services v4.1.3-2
install_LIS()
{
    wget https://download.microsoft.com/download/7/6/B/76BE7A6E-E39F-436C-9353-F4B44EF966E9/lis-rpms-4.1.3-2.tar.gz
	tar xvzf lis-rpms-4.1.3-2.tar.gz
	cd LISISO
	./install.sh
	cd ..
}

setup_user()
{
	yum -y install nfs-utils nfs-utils-lib

    mkdir -p $SHARE_HOME
    mkdir -p $SHARE_SCRATCH

	echo "$MASTER_NAME:$SHARE_HOME $SHARE_HOME    nfs4    rw,auto,_netdev 0 0" >> /etc/fstab
	mount -a
	mount
   
#    groupadd -g $HPC_GID $HPC_GROUP

    # Don't require password for HPC user sudo
    echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

	useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER

    chown $HPC_USER:$HPC_GROUP $SHARE_SCRATCH	
}

#install_applications

SETUP_MARKER=/var/local/cn-setup.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

# disable selinux
sed -i 's/enforcing/disabled/g' /etc/selinux/config
setenforce permissive

#install_azure_cli
#install_azure_files
#install_lsf

setup_user
install_ganglia

if [ "$SCHEDULER" == "pbspro" ]; then
	install_pbspro
fi

# elif [ "$SHARED_STORAGE" == "nfsonmaster" ]; then
	mount_nfs
# fi

install_applications

install_LIS

if [ "$SHARED_STORAGE" == "beegfs" ]; then
	install_beegfs_client
fi

# Create marker file so we know we're configured
touch $SETUP_MARKER

#shutdown -r +1 &
exit 0
