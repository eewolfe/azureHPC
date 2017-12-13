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

# Get number of users from post_install_args config parameter

# if [ -z ${@:2} ];then numusers=0; else numusers=${@:2}; fi
numusers=$3

# code to MasterServer
cfn_node_type="MasterServer"

echo "Provision base OS"
yum -y install epel-release

echo "Configuring SeisSpace"
export PROWESS_HOME=/shared/Landmark/SeisSpace5000.10.0/SeisSpace
export PROMAX_HOME=/shared/Landmark/SeisSpace5000.10.0/ProMAX
export DIR=$PROWESS_HOME/etc
export LM_LICENSE_FILE=2013@13.65.94.171
export PROWESS_HOST=$(hostname)
export PROWESS_PORT=5010
export PROWESS_DATA_PORT=3282
export LOGDIR=/etc/seisspace/logs
export INSTALL_DIR=/shared/Landmark/SeisSpace5000.10.0
export azstgacct=$1
export BLOBXFER_STORAGEACCOUNTKEY=$2

# Begin MasterServer block.
if [ $cfn_node_type == "MasterServer" ]; then

  echo "Provision Desktop"
  yum -y groupinstall Xfce
#  yum -y groupinstall "KDE Desktop"
#  yum -y install kde-workspace
  yum -y groupinstall Fonts
  yum -y install xorg-x11-utils*
  yum -y install xorg-x11-fonts-misc
  yum -y install xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi
  yum -y install tigervnc tigervnc-server
  yum -y install compat-libf2c-34
  yum -y install glibc-2.17
  yum -y install firefox
  yum -y install evince

  echo "Provision x2g0"
  yum -y install x2goserver-xsession
#  sed -i 's|" -nolisten tcp"|""|' /etc/x2go/x2goagent.options
  
#  echo "Provision aws cli"
#  yum -y install python-pip
#  pip install --upgrade pip
#  pip install awscli

#  Install blobxfer
echo "Provision blobxfer"
yum -y install epel-release gcc libffi-devel openssl-devel python-devel
yum -y install python-pip 
pip install --upgrade pip
pip install blobxfer --upgrade

  echo "Downloading Installation"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/seisspace-5000-10/ProMAX_SeisSpace_5000.10.0.0_lx64.tgz"
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
  
  echo "Install desktop service as centos"
  desktop_files centos

# sudo -u centos $DIR/install_desktop_files $PROWESS_HOME $PROMAX_HOME
  
# Create the default prefs directory
  echo "Creating default directory for users preferences"
  mkdir -p $PROWESS_HOME/../userprefs
  chmod 777 -R $PROWESS_HOME/../userprefs

# Fix fonts for ProMAX Motif tools . . . fonts are commented out
  echo "Updating ProMAX Motif app default fonts"
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/app_defaults.tgz"
  
  tar -zxvf app_defaults.tgz -C $PROMAX_HOME/port/lib/X11
  
  echo "Adding services entry for PD"
  $DIR/add_promax_service lgc_pd pd
  echo "Adding services entry for promax"
  $DIR/add_promax_service promax promax

# Add customized SeisSpace plugins
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/plugins.xml"
  
  service sitemanager stop
  service ssdataserver stop
  
  cat >/etc/seisspace/logs/netdir.xml <<EOF
<parset name="SeisSpace configuration">
  <parset name="SharedDataHomes">
    <parset name="/shared/data">
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
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/ProMAX_SeisSpace_5000.10.0.1_lx64.tgz"
  
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.1_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.1_patch_linux64.sh 

echo "Downloading 5000.10.0.2 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/ProMAX_SeisSpace_5000.10.0.2_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.2_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.2_patch_linux64.sh

echo "Downloading 5000.10.0.3 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/ProMAX_SeisSpace_5000.10.0.3_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.3_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.3_patch_linux64.sh

echo "Downloading 5000.10.0.4 Patch . . . "
  blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/ProMAX_SeisSpace_5000.10.0.4_lx64.tgz"
  echo "Untaring..."
  tar -xvzf ProMAX_SeisSpace_5000.10.0.4_lx64.tgz
  echo "Installing . . . "
  ./PatchInstall_ProMAX_SeisSpace_5000.10.0.4_patch_linux64.sh

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

# Install xpbs and xpbsmon not provided by cfncluster
blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/torque_xpbs.tgz"
  tar -zxvf torque_xpbs.tgz -C /opt/pbs

# Update hostname for xpbsmon
  sed -i "s/toyfj40/$HOSTNAME/g" /opt/pbs/lib/xpbsmon/xpbsmonrc
  sed -i "s/toyfj40/$HOSTNAME/g" /opt/pbs/lib/xpbs/xpbsrc

# Set up .vnc for the user
blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/centos_dot_vnc.tar"  
  tar -xvf ./centos_dot_vnc.tar -C /home/centos

# End of MasterServer block.
fi

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


# Set no host checking
set_user_ssh centos

# Add any requested users
add_users $numusers
  
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

# Download BenchmarkIO.arc
blobxfer download --storage-account $azstgacct --storage-account-key $BLOBXFER_STORAGEACCOUNTKEY --local-path . --remote-path "seisspace-5000-10/benchmarkIO_primary.arc"


echo "Finished"
