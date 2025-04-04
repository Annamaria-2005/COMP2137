#!/bin/bash

# lab3.sh — Deploy and run configure-host.sh on both containers and update local hosts
# Supports -verbose for extra output from the config script

# for enabling verbose mode if requested
VERBOSE_FLAG=""
if [[ "$1" == "-verbose" ]]; then
  VERBOSE_FLAG="-verbose"
  echo "Running in verbose mode..."
fi

# to check if configure-host.sh exists and is executable
if [[ ! -x ./configure-host.sh ]]; then
  echo "Error: configure-host.sh not found or not executable."
  exit 1
fi

echo "Deploying configure-host.sh to server1-mgmt..."
scp configure-host.sh remoteadmin@server1-mgmt:/root || { echo "Failed to copy to server1"; exit 1; }

echo "Running script on server1-mgmt..."
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh $VERBOSE_FLAG -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 || {
  echo "Failed to run configure-host.sh on server1"; exit 1; }

echo "Deploying configure-host.sh to server2-mgmt..."
scp configure-host.sh remoteadmin@server2-mgmt:/root || { echo "Failed to copy to server2"; exit 1; }

echo "Running script on server2-mgmt..."
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh $VERBOSE_FLAG -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 || {
  echo "Failed to run configure-host.sh on server2"; exit 1; }

echo "Updating local /etc/hosts..."
sudo ./configure-host.sh $VERBOSE_FLAG -hostentry loghost 192.168.16.3
sudo ./configure-host.sh $VERBOSE_FLAG -hostentry webhost 192.168.16.4

echo " Configuration applied successfully on all systems."
