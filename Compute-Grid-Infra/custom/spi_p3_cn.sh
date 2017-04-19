#!/bin/bash

set -x

########################################
# Set up functions needed in the script
########################################

###########################
# Function to add a user
###########################

function add_users() {

user_count=1
while [ $user_count -le $1 ]
 do

  adduser -g centos -b /shared/home ssuser${user_count}
  echo "ssuser${user_count}:ssuser${user_count}pw" | chpasswd

# Set up for passwordless ssh
  set_user_ssh ssuser${user_count}



  ((user_count++))
 done

}

##################################
# Function to set passwordless ssh
##################################

function set_user_ssh() {

eval home_dir=`getent passwd $1 | cut -d: -f6`

if [ ! -d "${home_dir}/.ssh" ]; then
 mkdir -m 700 ${home_dir}/.ssh
fi

cat << EOF > ${home_dir}/.ssh/config
Host *
  StrictHostKeyChecking=no
  UserKnownHostsFile=/dev/null
EOF

chown -R $1:centos ${home_dir}

if [ ! -e "${home_dir}/.ssh/authorized_keys" ]; then
su -c 'cat /dev/zero | ssh-keygen -q -N "" -t rsa' $1
su -c 'cat /dev/zero | ssh-keygen -q -N "" -t rsa1' $1
su -c 'cat /dev/zero | ssh-keygen -q -N "" -t dsa' $1
cat ${home_dir}/.ssh/*.pub >> ${home_dir}/.ssh/authorized_keys
cat /home/centos/.ssh/authorized_keys >> ${home_dir}/.ssh/authorized_keys
fi

chmod 700 ${home_dir}/.ssh
chmod 600 ${home_dir}/.ssh/config
chmod 600 ${home_dir}/.ssh/authorized_keys
chown $1:centos ${home_dir}/.ssh/authorized_keys
  
}



#################################
# Run the script
##################################

######################################
# Get command line arguments, if any
######################################

numusers=$1

echo "Provision base OS"
yum -y install epel-release
yum -y install libXp*-devel

echo "Configuring SeisSpace"
export PROWESS_HOME=/shared/Landmark/SeisSpace5000.10.0/SeisSpace
export PROMAX_HOME=/shared/Landmark/SeisSpace5000.10.0/ProMAX
export DIR=$PROWESS_HOME/etc
export LM_LICENSE_FILE=2013@52.45.231.227
export PROWESS_HOST=$(hostname)
export PROWESS_PORT=5010
export PROWESS_DATA_PORT=3282
export LOGDIR=/etc/seisspace/logs
export INSTALL_DIR=/shared/Landmark/SeisSpace5000.10.0
 

# This runs on all nodes.
echo "Check for missing packages"
printf "y\ny\n" | $DIR/check_packages

echo "Disabling transparent huge page compaction."
_COMMAND="echo never > /sys/kernel/mm/transparent_hugepage/defrag"
echo "Disabling transparent huge page compaction now and for future restarts."
sh -c "$_COMMAND"
echo "Creating /etc/rc.local.bak"
sed -i.bak "/transparent_hugepage/d" /etc/rc.local
echo "Updating /etc/rc.local."
sh -c "echo -e \"\n# Disable transparent huge page compaction.\n$_COMMAND\" >>/etc/rc.local"

# Make the shared directory that is mounted from the master node
  echo "Create data home in shared directory:"
  chmod 777 /shared/data
  chmod 777 /shared/home

# Set no host checking
set_user_ssh centos

# Add any requested users
add_users $numusers
  
# Mount the EFS filesystem
# echo "Mount EFS filesystem"
# mkdir -p /data/efs
# mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).fs-261eca6f.efs.us-east-1.amazonaws.com:/ /data/efs

echo "Centos 7 only..."
ver=$(rpm -q --queryformat '%{VERSION}' centos-release)
echo "version=$ver"
if [ "$ver" -gt 6  ]; then
  # Hack for openmotif
  echo "Installing openmotif because the configure script will fail for this package on 7.x"
  yum -y install openmotif
  if [ ! -L "/usr/lib64/libXm.so.3" ]; then 
    echo "Add symbolic link for libXm.so.3"
    ln -s /usr/lib64/libXm.so.4 /usr/lib64/libXm.so.3
  fi
  # Increase the number of process threads RHEL 7
 sed -i 's|4096|16384|' /etc/security/limits.d/20-nproc.conf
else
  # Increase the number of process threads RHEL 6
 sed -i 's|1024|16384|' /etc/security/limits.d/90-nproc.conf
fi

echo "Finished"
