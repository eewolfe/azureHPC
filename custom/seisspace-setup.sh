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

chown -R $1:users ${home_dir}

if [ ! -e "${home_dir}/.ssh/authorized_keys" ]; then
su -c 'cat /dev/zero | ssh-keygen -q -N "" -t rsa' $1
cat ${home_dir}/.ssh/*.pub >> ${home_dir}/.ssh/authorized_keys
fi

chmod 700 ${home_dir}/.ssh
chmod 600 ${home_dir}/.ssh/config
chmod 600 ${home_dir}/.ssh/authorized_keys
chown $1:users ${home_dir}/.ssh/authorized_keys
  
}

#######################################
# Install desktop files
#######################################

function desktop_files () {

  echo "Install desktop files as $1"
  sudo -u $1 $DIR/install_desktop_files $PROWESS_HOME $PROMAX_HOME

}

#######################################
# Install Azure blobfuse
#######################################

install_blobfuse () {

  rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
  yum -y install blobfuse

  mkdir -m 777 $BLOBFUSEDIR
  mkdir -m 777 $BLOBMNT
  mkdir -m 755 $BLOBETC

  echo "accountName=" >> $BLOBETC/connection.cfg
  echo "accountKey=" >> $BLOBETC/connection.cfg
  echo "containerName=" >> $BLOBETC/connection.cfg
 
 # Cannot mount till the connection.cfg is completed
 # blobfuse $BLOBMNT --tmp-path=$BLOBFUSEDIR -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=$BLOBETC/connection.cfg

}

##############################################
# Make sure the beegfs is started and mounted
##############################################

function start_beegfs () {

systemctl start beegfs-client.service
systemctl status beegfs-client.service
systemctl start beegfs-admon.service
systemctl start beegfs-helperd.service
systemctl start beegfs-client.service
systemctl status beegfs-client.service

}

#######################################
# Setup system
#######################################

setup_system () {
echo "Downloading script to join a domain"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/domain_join-cvx.sh"
echo "Joining a domain . . . "
chmod +x domain_join-cvx.sh
./domain_join-cvx.sh

echo "Downloading script to configure samba"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/samba_config-cvx.sh"
ehco "Starting samba . . . "
chmod +x ./samba_config-cvx.sh
./samba_config-cvx.sh

}

#################################
# Run the script
##################################

######################################
# Get command line arguments, if any
######################################

# Initialize arguments

echo "Command line arguments are $@"

numusers=$3

# Be sure the beegfs has started
echo "Starting beegfs . . ."
start_beegfs

echo "Provision base OS"
yum -y install epel-release
yum -y install epel

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
export BLOBDIR="cxv-deploy"
export BLOBFUSEDIR=/shared/data/blobsa
export BLOBETC=/etc/sysconfig/blobfuse
export BLOBMNT=/mnt/blobdir

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
 pip install --upgrade --force-reinstall pip==9.0.3
 pip install blobxfer --disable-pip-version-check
 pip install --upgrade pip
 pip install blobxfer --upgrade

echo "Provision x2g0"
 yum -y --enablerepo=epel install x2goserver-xsession

 yum groupinstall "Xfce" -y
 yum groupinstall "Fonts" -y

  echo "Downloading Installation"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/ProMAX_SeisSpace_5000.10.0.0_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.0_lx64.tgz
  
  echo "Starting install"
cat >> installer.properties <<EOF
USER_INSTALL_DIR=/shared/Landmark/SeisSpace5000.10.0
-fileOverwrite_/shared/Landmark/SeisSpace5000.10.0/_ProMaxSeisSpace5000.10.0_installation/Change ProMaxSeisSpace5000.10.0 Installation.lax=Yes
-fileOverwrite_/share/Landmark/SeisSpace5000.10.0/ProMAX/promax_core.tgz=Yes
-fileOverwrite_/shared/Landmark/SeisSpace5000.10.0/SeisSpace/install-linux64.tar.gz=Yes
-fileOverwrite_/shared/Landmark/SeisSpace5000.10.0/fwi/fwi_distribution.tgz=Yes
-fileOverwrite_/shared/Landmark/SeisSpace5000.10.0/cwt/cwt.tgz=Yes
-fileOverwrite_/shared/Landmark/SeisSpace5000.10.0/ldi/ldi.tgz=Yes
EOF
  sh ./ProMaxSeisSpace.bin -f installer.properties -i Silent

# Remove tty requirement for sudo
  sed -i 's/requiretty/!requiretty/g' /etc/sudoers
  
  echo "Install sitemanager service"
  $DIR/install_sitemanager_service $PROWESS_HOME $PROMAX_HOME $LOGDIR $PROWESS_PORT
  
  echo "Install ssdata service"
  $DIR/install_ssdataserver_service $PROWESS_HOME $PROMAX_HOME $LOGDIR $PROWESS_HOST $PROWESS_PORT $PROWESS_DATA_PORT
  
# Create the default prefs directory
  echo "Creating default directory for users preferences"
  mkdir -p $PROWESS_HOME/../userprefs
  chmod 777 -R $PROWESS_HOME/../userprefs

# Fix fonts for ProMAX Motif tools . . . fonts are commented out
  echo "Updating ProMAX Motif app default fonts"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/app_defaults.tgz"
  
  tar -zxvf app_defaults.tgz -C $PROMAX_HOME/port/lib/X11

# Add customized SeisSpace plugins
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/plugins.xml"
  
  service sitemanager stop
  service ssdataserver stop
  
  cat >/etc/seisspace/logs/netdir.xml <<EOF
<parset name="SeisSpace configuration">
  <parset name="SharedDataHomes">
    <parset name="/shared/data/primary">
      <par name="DescName" type="string"> "" </par>
      <par name="JSSecondaryPrefix" type="string"> "" </par>
      <parset name="environment">
        <par name="PROMAX_SCRATCH_HOME" type="string"> /mnt/resource </par>
        <par name="PROMAX_ETC_HOME" type="string"> /shared/Landmark/SeisSpace5000.10.0/ProMAX/etc </par>
      </parset>
    </parset>
  </parset>
</parset>
EOF

# Hack to get around some open process
  
  echo "service sitemanager start" | at now
  echo "service ssdataserver start" | at now

# Install 5000.10.0.1 patch and RPMS needed for patch

  yum install -y sharutils
  yum install -y ncompress

echo "Downloading 5000.10.0.1 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/ProMAX_SeisSpace_5000.10.0.1_lx64.tgz"
  
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.1_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.1_patch_linux64.sh 

echo "Downloading 5000.10.0.2 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/ProMAX_SeisSpace_5000.10.0.2_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.2_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.2_patch_linux64.sh

echo "Downloading 5000.10.0.3 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/ProMAX_SeisSpace_5000.10.0.3_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.3_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.3_patch_linux64.sh

echo "Downloading 5000.10.0.4 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/ProMAX_SeisSpace_5000.10.0.4_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.4_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.4_patch_linux64.sh
  
  echo "Downloading 5000.10.0.5 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/ProMAX_SeisSpace_5000.10.0.5_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.5_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.5_patch_linux64.sh

  echo "PROWESS_HOME=$PROWESS_HOME"
  echo "PROMAX_HOME=$PROMAX_HOME"
  echo "DIR=$DIR"
  echo "LM_LICENSE_FILE=$LM_LICENSE_FILE"
  echo "PROWESS_HOST=$PROWESS_HOST"
  echo "PROWESS_PORT=$PROWESS_PORT"
  echo "PROWESS_DATA_PORT=$PROWESS_DATA_PORT"
  echo "LOGDIR=$LOGDIR"
  
  echo "Updating seisspace.conf"
  sed -i 's|^export PROWESS_HOME.*|export PROWESS_HOME='$PROWESS_HOME'|' $DIR/seisspace.conf
  sed -i 's|^export PROMAX_HOME.*|export PROMAX_HOME='$PROMAX_HOME'|' $DIR/seisspace.conf
  sed -i 's|^export LM_LICENSE_FILE.*|export LM_LICENSE_FILE='$LM_LICENSE_FILE'|' $DIR/seisspace.conf
  sed -i 's|^export PROWESS_HOST.*|export PROWESS_HOST='$PROWESS_HOST'|' $DIR/seisspace.conf
  sed -i 's|^export PROWESS_PORT.*|export PROWESS_PORT='$PROWESS_PORT'|' $DIR/seisspace.conf
  sed -i 's|^export PROWESS_DATA_SERVER_PORT.*|export PROWESS_DATA_SERVER_PORT='$PROWESS_DATA_PORT'|' $DIR/seisspace.conf

  echo "Updating SSclient-new for umask"
  sed -i 's|#!/bin/bash|#!/bin/bash\numask 002|' $DIR/SSclient-new

  echo "Updating prowess.properties"
  sed -i 's|,xterm|,xfce4-terminal,xterm|' $DIR/prowess.properties

  echo "Setup Torque queues"
cat >> qconfig_pbs <<EOF
#
# pbs batch queues
#
name = parallel
type = batch 
description = "parallel job batch queue"
function = pbs_submit
menu = que_res_pbs.menu
machine =  `hostname`
properties = local

name = serial
type = batch 
description = "serial job batch queue"
function = pbs_submit
menu = que_res_pbs.menu
machine = `hostname`
properties = local
EOF

cp qconfig_pbs $PROMAX_HOME/etc/qconfig_pbs

# Hack to put real PBS bin path into the quedelete script
sed -i 's|PBS_BIN=/usr/local/bin|PBS_BIN=/opt/pbs/bin|' $PROMAX_HOME/sys/exe/pbs/quedelete

/opt/pbs/bin/qmgr << "EOF"
c q serial queue_type=execution
c q parallel queue_type=execution
s q serial enabled=true, started=true, max_user_run=1
s q parallel enabled=true, started=true
set server scheduling=true
s s scheduler_iteration=30
s s node_pack=false
s s query_other_jobs=true
print server
EOF

# Install xpbs and xpbsmon not provided by azure
blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "$BLOBDIR/torque_xpbs.tgz"
  tar -zxvf torque_xpbs.tgz -C /opt/pbs

# Update hostname for xpbsmon
  sed -i "s/toyfj40/$HOSTNAME/g" /opt/pbs/lib/xpbsmon/xpbsmonrc
  sed -i "s/toyfj40/$HOSTNAME/g" /opt/pbs/lib/xpbs/xpbsrc

# Adding service entries to every machine that may run a SeisSpace job
  echo "Adding services entry for PD"
  $DIR/add_promax_service lgc_pd pd
  echo "Adding services entry for promax"
  $DIR/add_promax_service promax promax

# This runs on all nodes.
echo "Check for missing packages"
# Hack to set to version 7 
sed -i 's|echo \"version=\$ver\"|ver=7|' $PROWESS_HOME/etc/check_packages
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

mkdir -m 777 -p /shared/data/downloads
mkdir -m 777 -p /shared/data/primary

# Install and setup for blobfuse
# install_blobfuse

# Setup system
setup_system

# Download some tutorial and benchmark archive files
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path /shared/data/downloads --remote-path "$BLOBDIR/benchmarksIO_primary.arc"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path /shared/data/downloads --remote-path "$BLOBDIR/2d_3d_4d_vsp_ldi_cwt_tutorials_5000.10.0.x.tgz"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path /shared/data/downloads --remote-path "$BLOBDIR/Landmark_Depth_Imaging5000.8.5.0_Lx64.tgz"

echo "Finished"

exit 0
