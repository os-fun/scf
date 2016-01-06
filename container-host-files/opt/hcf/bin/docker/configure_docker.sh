#!/bin/bash

# Usage: configure_docker.sh <IP_ADDRESS>
ip_address=$1

# allow us to pull from the docker registry
echo DOCKER_OPTS=\"--cluster-store=etcd://${ip_address}:3379 --cluster-advertise=${ip_address}:2376 --label=com.docker.network.driver.overlay.bind_interface=eth0 -H=${ip_address}:2376 -H=unix:///var/run/docker.sock -s=devicemapper -g=/data/docker \" | sudo tee -a /etc/default/docker

# enable cgroup memory and swap accounting
sudo sed -idockerbak 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"/' /etc/default/grub
sudo update-grub

sudo sed -idockerbak 's/local-filesystems and net-device-up IFACE!=lo/local-filesystems and net-device-up IFACE!=lo and started etcd/' /etc/init/docker.conf
