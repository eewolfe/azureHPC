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

chown -R $1:users ${home_dir}

if [ ! -e "${home_dir}/.ssh/authorized_keys" ]; then
su -c 'cat /dev/zero | ssh-keygen -q -N "" -t rsa' $1
cat ${home_dir}/.ssh/*.pub >> ${home_dir}/.ssh/authorized_keys
cat /home/centos/.ssh/authorized_keys >> ${home_dir}/.ssh/authorized_keys
fi

chmod 700 ${home_dir}/.ssh
chmod 600 ${home_dir}/.ssh/config
chmod 600 ${home_dir}/.ssh/authorized_keys
chown $1:users ${home_dir}/.ssh/authorized_keys
  
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
