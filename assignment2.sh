#!/bin/bash

set -e  # for exiting on error
set -u  # to treat unset variables as errors
set -o pipefail  # for catching errors in pipelines

log() {
    echo -e "[INFO] $1"
}

error_exit() {
    echo -e "[ERROR] $1" >&2
    exit 1
}

#in order to ensure script runs as root
if [[ $EUID -ne 0 ]]; then
    error_exit "run as root- Use sudo."
fi

# for finding out the correct Netplan file
NETPLAN_FILE=$(find /etc/netplan/ -type f -name "*.yaml" | head -n 1)
if [[ -z "$NETPLAN_FILE" ]]; then
    error_exit "No Netplan configuration file found in /etc/netplan/"
fi

if grep -q "192.168.16.21/24" "$NETPLAN_FILE"; then
    log "Netplan configuration already set."
else
    log "for updating Netplan configuration in $NETPLAN_FILE."
    chmod 600 "$NETPLAN_FILE"
    cat > "$NETPLAN_FILE" <<EOL
network:
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.16.21/24
      routes:
        - to: default
          via: 192.168.16.2
  version: 2
EOL
    chmod 644 "$NETPLAN_FILE"
    netplan apply || error_exit "Failed to apply Netplan configuration."
fi

# for updating /etc/hosts
HOSTS_FILE="/etc/hosts"
if grep -q "192.168.16.21 server1" "$HOSTS_FILE"; then
    log "/etc/hosts is already configured."
else
    log "Updating /etc/hosts."
    sed -i '/server1/d' "$HOSTS_FILE"
    echo "192.168.16.21 server1" >> "$HOSTS_FILE"
fi

# this is to install required packages
log "Installing required software packages."
apt update -y && apt install -y apache2 squid || error_exit "Failed to install required software."

# to enable and start services
log "Enabling and starting services."
systemctl enable --now apache2 squid || error_exit "Failed to start required services."

# User list
USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

# Configure users
for USER in "${USERS[@]}"; do
    if id "$USER" &>/dev/null; then
        log "User $USER already exists."
    else
        log "Creating user $USER."
        useradd -m -s /bin/bash "$USER" || error_exit "Failed to create user $USER."
    fi

    # to generate SSH keys if they don't exist
    USER_HOME="/home/$USER"
    SSH_DIR="$USER_HOME/.ssh"
    mkdir -p "$SSH_DIR"
    chown "$USER:$USER" "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # to generate RSA key
    if [[ ! -f "$SSH_DIR/id_rsa.pub" ]]; then
        log "Generating RSA SSH key for $USER."
        sudo -u "$USER" ssh-keygen -t rsa -b 4096 -N "" -f "$SSH_DIR/id_rsa"
    fi

    # to generate Ed25519 key
    if [[ ! -f "$SSH_DIR/id_ed25519.pub" ]]; then
        log "Generating Ed25519 SSH key for $USER."
        sudo -u "$USER" ssh-keygen -t ed25519 -N "" -f "$SSH_DIR/id_ed25519"
    fi

    # for adding keys to authorized_keys
    cat "$SSH_DIR/id_rsa.pub" "$SSH_DIR/id_ed25519.pub" > "$SSH_DIR/authorized_keys"
    chown "$USER:$USER" "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/authorized_keys"

done

# Special configuration for dennis
if id "dennis" &>/dev/null; then
    log "Ensuring dennis has sudo access."
    usermod -aG sudo dennis
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "/home/dennis/.ssh/authorized_keys"
fi

log "Script execution completed successfully."
