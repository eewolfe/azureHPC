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

  adduser -u 700${user_count} -g users -b /shared/home ssuser${user_count}
  echo "ssuser${user_count}:ssuser${user_count}pw" | chpasswd

  ((user_count++))
 done

}

#####################################
# Function to setup system parameters
#####################################

setup_system()
{

# Disable transparent huge pages and open permissions on /mnt/resource
echo "Disabling transparent huge page compaction."
_COMMAND="echo never > /sys/kernel/mm/transparent_hugepage/defrag"
echo "Disabling transparent huge page compaction now and for future restarts"
sh -c "$_COMMAND"
echo "Creating /etc/rc.d/rc.local.bak"
sed -i.bak "/transparent_hugepage/d" /etc/rc.d/rc.local
echo "Updating /etc/rc.d/rc.local"
sh -c "echo -e \"\n# Disable transparent huge page compaction.\n$_COMMAND\" >>/etc/rc.d/rc.local"
sh -c "echo -e \"chmod 777 /mnt/resource\" >> /etc/rc.d/rc.local"
chmod u+x /etc/rc.d/rc.local
systemctl start rc-local

# Increase the number of available processes
sed -i 's|4096|16384|' /etc/security/limits.d/20-nproc.conf

# Hack for openmotif
  echo "Installing openmotif because the configure script will fail for this package on 7.x"
  yum -y install openmotif
  if [ ! -L "/usr/lib64/libXm.so.3" ]; then
    echo "Add symbolic link for libXm.so.3"
    ln -s /usr/lib64/libXm.so.4 /usr/lib64/libXm.so.3
  fi
  
    systemctl enable rpcbind || echo "Already enabled"
    systemctl start rpcbind || echo "Already enabled"

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

echo "Configuring SeisSpace Variables"
export PROWESS_HOME=/shared/Landmark/SeisSpace5000.10.0/SeisSpace
export PROMAX_HOME=/shared/Landmark/SeisSpace5000.10.0/ProMAX
export DIR=$PROWESS_HOME/etc
 
# This runs on all nodes.
echo "Check for missing packages"
printf "y\ny\n" | $DIR/check_packages

# Add any requested users
add_users $numusers
  
# Setup system parameters
setup_system

echo "Finished"
