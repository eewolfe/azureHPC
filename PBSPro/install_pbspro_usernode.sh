#!/bin/bash

set -x

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ $# != 1 ]; then
    echo "Usage: $0 <MasterHostname>"
    exit 1
fi

# Set user args
MASTER_HOSTNAME=$1
PBS_MANAGER=hpcsvc

# Downloads and installs PBS Pro OSS on the node.
#
install_pbspro()
{    
    wget -O /mnt/CentOS_7.zip  http://wpc.23a7.iotacdn.net/8023A7/origin2/rl/PBS-Open/CentOS_7.zip
    unzip /mnt/CentOS_7.zip -d /mnt
       
    yum install -y hwloc-devel expat-devel tcl-devel expat
    rpm -ivh --nodeps /mnt/CentOS_7/pbspro-execution-14.1.0-13.1.x86_64.rpm

        cat > /etc/pbs.conf << EOF
PBS_SERVER=$MASTER_HOSTNAME
PBS_START_SERVER=0
PBS_START_SCHED=0
PBS_START_COMM=0
PBS_START_MOM=1
PBS_EXEC=/opt/pbs
PBS_HOME=/var/spool/pbs
PBS_CORE_LIMIT=unlimited
PBS_SCP=/bin/scp
EOF
    echo 'export PATH=/opt/pbs/bin:$PATH' >> /etc/profile.d/pbs.sh
    echo 'export PATH=/opt/pbs/sbin:$PATH' >> /etc/profile.d/pbs.sh
}

SETUP_MARKER=/var/local/install_pbspro.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

install_pbspro

# Create marker file so we know we're configured
touch $SETUP_MARKER
