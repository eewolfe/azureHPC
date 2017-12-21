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

  adduser -u 700${user_count} -g centos -b /shared/home ssuser${user_count}
  echo "ssuser${user_count}:ssuser${user_count}pw" | chpasswd

# Set up for passwordless ssh
  set_user_ssh ssuser${user_count}

# Install desktop files
  desktop_files ssuser${user_count}

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
cat ${home_dir}/.ssh/*.pub >> ${home_dir}/.ssh/authorized_keys
cat /home/centos/.ssh/authorized_keys >> ${home_dir}/.ssh/authorized_keys
fi

chmod 700 ${home_dir}/.ssh
chmod 600 ${home_dir}/.ssh/config
chmod 600 ${home_dir}/.ssh/authorized_keys
chown $1:centos ${home_dir}/.ssh/authorized_keys
  
}

#######################################
# Install desktop files
#######################################

function desktop_files () {

  echo "Install desktop files as $1"
  sudo -u $1 $DIR/install_desktop_files $PROWESS_HOME $PROMAX_HOME

}

#################################
# Run the script
##################################

######################################
# Get command line arguments, if any
######################################

# Initialize arguments

echo "Command line arguments are $@"

# Get the number of users from the command line.
numusers=$1

echo "Provision base OS"
yum -y install epel-release

echo "Configuring SeisSpace"
export PROWESS_HOME=/shared/Landmark/SeisSpace5000.10.0/SeisSpace
export PROMAX_HOME=/shared/Landmark/SeisSpace5000.10.0/ProMAX
export DIR=$PROWESS_HOME/etc
export LM_LICENSE_FILE=2013@13.84.128.69
export PROWESS_HOST=$(hostname)
export PROWESS_PORT=5010
export PROWESS_DATA_PORT=3282
export LOGDIR=/etc/seisspace/logs
export INSTALL_DIR=/shared/Landmark/SeisSpace5000.10.0
export azstgacct=$1
export BLOBXFER_STORAGEACCOUNTKEY=$2
export BLOBDIR="5000-10-scripts"

  echo "Provision Desktop"
  yum -y install xorg-x11-utils*
  yum -y install xorg-x11-fonts-misc
  yum -y install xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi
  yum -y install tigervnc tigervnc-server
  yum -y install compat-libf2c-34
  yum -y install glibc-2.17
  yum -y install firefox
  yum -y install evince
  yum -y install redhat-lsb-core

#  Install blobxfer
echo "Provision blobxfer"
yum -y install epel-release gcc libffi-devel openssl-devel python-devel

#  Download and install pip for RHEL 7
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm

wget https://pypi.python.org/packages/source/s/setuptools/setuptools-7.0.tar.gz --no-check-certificate
tar xzf setuptools-7.0.tar.gz
cd setuptools-7.0
python setup.py install
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
cd ..

pip install blobxfer --upgrade

echo "Provision x2g0"
 yum -y --enablerepo=epel install x2goserver-xsession.x86_64

 yum groupinstall "Xfce" -y
 yum groupinstall "Fonts" -y

# Remove tty requirement for sudo
  sed -i 's/requiretty/!requiretty/g' /etc/sudoers
  
# Adding service entries to every machine that may run a SeisSpace job
  echo "Adding services entry for PD"
  $DIR/add_promax_service lgc_pd pd
  echo "Adding services entry for promax"
  $DIR/add_promax_service promax promax

echo "Check for missing packages"
# Hack to set to version 7 
printf "y\ny\n" | $DIR/check_packages

# Set no host checking
set_user_ssh centos

# Add any requested users
add_users $numusers
  
  # Hack for openmotif
  echo "Installing openmotif because the configure script will fail for this package on 7.x"
  yum -y install openmotif
  if [ ! -L "/usr/lib64/libXm.so.3" ]; then 
    echo "Add symbolic link for libXm.so.3"
    ln -s /usr/lib64/libXm.so.4 /usr/lib64/libXm.so.3
  fi


echo "Finished"

