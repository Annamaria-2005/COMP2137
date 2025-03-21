#!/bin/bash

# Gather system information
USERNAME=$(whoami)
DATETIME=$(date)
HOSTNAME=$(hostname)
OS="Unknown OS"
if [ -r /etc/os-release ]; then
    OS=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
fi

UPTIME=$(uptime -p)
# Hardware Information
CPU=$(lscpu | awk -F': ' '/Model name/ {print $2}')
CPU_CORES=$(nproc)
CPU_SPEED=$(lscpu | awk '/CPU MHz/ {print $3 " MHz"}')
RAM=$(free -h | awk '/^Mem:/ {print $2}')
DISKS=$(lsblk -d -o NAME,VENDOR,MODEL,SIZE | grep -v "NAME" | column -t)
VIDEO=$(lspci | grep -Ei 'vga|3d|display' | awk -F': ' '{print $2}')
# Network Information
FQDN=$(hostname -f)
HOST_IP=$(ip route | awk '/default/ {print $9}')
GATEWAY=$(ip route | awk '/default/ {print $3}')
DNS=$(awk '/nameserver/ {print $2}' /etc/resolv.conf)

# System Status
USERS_LOGGED_IN=$(who | awk '{print $1}' | sort -u | paste -sd ", ")
DISK_SPACE=$(df -h | awk '/^\/dev/ {print $6 " " $4}' | column -t)
PROCESS_COUNT=$(ps aux --no-heading | wc -l)
LOAD_AVG=$(awk '{print $1, $2, $3}' /proc/loadavg)
LISTENING_PORTS=$(ss -tuln | awk '{print $5}' | awk -F':' 'NF>1 {print $NF}' | sort -nu | paste -sd ", ")
UFW_STATUS=$(sudo ufw status | awk '/Status:/ {print $2}')

# Output Report
printf "\nSystem Report generated by %s, %s\n" "$USERNAME" "$DATETIME"
echo ""
echo "System Information"
echo "------------------"
echo "Hostname: $HOSTNAME"
echo "OS: $OS"
echo "Uptime: $UPTIME"
echo ""
echo "Hardware Information"
echo "--------------------"
echo "CPU: $CPU ($CPU_CORES cores, $CPU_SPEED)"
echo "RAM: $RAM"
echo "Disk(s):"
echo "$DISKS"
echo "Video: $VIDEO"
echo ""
echo "Network Information"
echo "-------------------"
echo "FQDN: $FQDN"
echo "Host Address: $HOST_IP"
echo "Gateway IP: $GATEWAY"
echo "DNS Server: $DNS"
echo ""
echo "System Status"
echo "-------------"
echo "Users Logged In: $USERS_LOGGED_IN"
echo "Disk Space:"
echo "$DISK_SPACE"
echo "Process Count: $PROCESS_COUNT"
echo "Load Averages: $LOAD_AVG"
echo "Listening Network Ports: $LISTENING_PORTS"
echo "UFW Status: $UFW_STATUS"
echo ""
