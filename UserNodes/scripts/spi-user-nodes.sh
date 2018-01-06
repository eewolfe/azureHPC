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

##################################
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
printf "y\ny\n" | $DIR/check_packages

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

