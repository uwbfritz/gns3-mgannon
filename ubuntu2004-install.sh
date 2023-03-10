#!/usr/bin/env bash

#--------------------------------------------------------------------------------------------------------------------------------
#  *                              Ubuntu2004Install
#    
#    Author: Bill Fritz
#    Description: GNS3 Ubuntu 20.04 Install (This script assumes the desktop environment is already installed)
#    Last Modified: 2023-03-10
#    
#--------------------------------------------------------------------------------------------------------------------------------

function preflight(){
  # Fail if not root
  if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
  fi
  # Check if ubuntu 20.04
  if [ "$(lsb_release -rs)" != "20.04" ]
    then echo "This script is for Ubuntu 20.04"
    exit
  fi
}

function baseconfig(){
  # Install base configs
  apt update
  apt upgrade
  add-apt-repository ppa:gns3/ppa
}

function gns3install(){
  # Install GNS3 (Answer yes, yes)
  sudo apt-get update
  sudo apt-get install gns3-server gns3-gui

  # IOU Support
  dpkg --add-architecture i386
  apt update
  apt install gns3-iou

  # Install Docker-ce
  apt remove docker docker-engine docker.io 2>/dev/null
  apt -y install lsb-release gnupg apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
  add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt update
  apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  usermod -aG docker "$(whoami)"
  newgrp docker

  # Virt Support
  usermod -aG ubridge libvirt kvm wireshark "$USER"
}

function main(){
  preflight
  baseconfig
  gns3install
  echo "Server installed. Type 'gns3' to start the GUI"
}

main