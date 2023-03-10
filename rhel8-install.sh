#!/usr/bin/env bash

#--------------------------------------------------------------------------------------------------------------------------------
#  *                              Rhel8Install - GNS3
#    
#    Author: Bill Fritz
#    Description: Provision GNS3 VM with RHEL 8 and GNS3 (This script assumes the desktop environment is already installed)
#    Last Modified: 2023-03-10
#    
#--------------------------------------------------------------------------------------------------------------------------------


function preflight(){
    # Check if RHEL
    if [ "$(cat /etc/redhat-release | grep -o 'Red Hat Enterprise Linux')" != "Red Hat Enterprise Linux" ]
        then echo "This script is for RHEL 8"
        exit
    fi

    # Fail if not root
    if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
    fi
}

function baseconfig(){
    # Disable SELinux
    setenforce 0
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    # Install base configs
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
    dnf install dnf-plugins-core -y
    dnf config-manager --set-enabled powertools
    # Dev tools
    dnf -y install python3-devel elfutils-libelf-devel libpcap-devel python3-pyqt5-sip python3-qt5 xterm cmake
    dnf -y groupinstall "Development Tools"
    python3 -m pip install --upgrade pip
    # Install Docker-ce
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y docker-ce
    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    # Add to docker group
    usermod -a -G docker "$(whoami)"
}

function gns3build(){
    # GNS3 Src
    mkdir ~/gns3
    cd ~/gns3 || exit
    git clone https://github.com/GNS3/gns3-server.git
    git clone https://github.com/GNS3/gns3-gui.git
    git clone https://github.com/GNS3/vpcs.git
    git clone https://github.com/GNS3/dynamips.git
    git clone https://github.com/GNS3/ubridge.git

    cd ~/gns3/gns3-server/ || exit
    pip3 install -r requirements.txt
    python3 setup.py install

    cd ~/gns3/gns3-gui/ || exit
    pip3 install -r requirements.txt
    python3 setup.py install
    cp resources/linux/applications/gns3.desktop /usr/share/applications/
    cp -R resources/linux/icons/hicolor/ /usr/share/icons/

    cd ~/gns3/vpcs/src || exit
    ./mk.sh
    cp vpcs /usr/local/bin/vpcs

    cd ~/gns3/dynamips/ || exit
    mkdir build 
    cd build/ || exit
    cmake ..
    make
    make install

    cd ~/gns3/ubridge || exit
    make
    make install

}

function main(){
    preflight
    baseconfig
    gns3build
    echo "Server installed. Type 'gns3' to start the GUI"
}

main