#!/bin/bash

#for ignoring TERM, HUP, INT
trap '' TERM HUP INT

VERBOSE=false

# a function to log and optionally print
log_and_echo() {
  if $VERBOSE; then echo "$1"; fi
  logger "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -verbose)
      VERBOSE=true
      shift
      ;;
    -name)
      DESIRED_NAME="$2"
      shift 2
      ;;
    -ip)
      DESIRED_IP="$2"
      shift 2
      ;;
    -hostentry)
      HOSTENTRY_NAME="$2"
      HOSTENTRY_IP="$3"
      shift 3
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# to apply hostname if needed
if [[ -n "$DESIRED_NAME" ]]; then
  CURRENT_NAME=$(hostname)
  if [[ "$CURRENT_NAME" != "$DESIRED_NAME" ]]; then
    echo "$DESIRED_NAME" > /etc/hostname
    hostname "$DESIRED_NAME"
    sed -i "s/127.0.1.1.*/127.0.1.1 $DESIRED_NAME/" /etc/hosts
    log_and_echo "Hostname changed from $CURRENT_NAME to $DESIRED_NAME"
  else
    $VERBOSE && echo "Hostname already set to $DESIRED_NAME"
  fi
fi

# for applying IP address if needed (assumes netplan setup)
if [[ -n "$DESIRED_IP" ]]; then
  LAN_IFACE=$(ip -o -4 route show to default | awk '{print $5}')
  CURRENT_IP=$(ip -4 addr show $LAN_IFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
  if [[ "$CURRENT_IP" != "$DESIRED_IP" ]]; then
    sed -i "/$LAN_IFACE:/,/addresses:/ s/addresses:.*/addresses: [$DESIRED_IP\/24]/" /etc/netplan/*.yaml
    netplan apply
    sed -i "/$DESIRED_NAME/d" /etc/hosts
    echo "$DESIRED_IP $DESIRED_NAME" >> /etc/hosts
    log_and_echo "IP changed on $LAN_IFACE to $DESIRED_IP"
  else
    $VERBOSE && echo "IP already set to $DESIRED_IP"
  fi
fi

# for adding or updating host entry
if [[ -n "$HOSTENTRY_NAME" && -n "$HOSTENTRY_IP" ]]; then
  if grep -q "$HOSTENTRY_NAME" /etc/hosts; then
    CURRENT_ENTRY=$(grep "$HOSTENTRY_NAME" /etc/hosts | awk '{print $1}')
    if [[ "$CURRENT_ENTRY" != "$HOSTENTRY_IP" ]]; then
      sed -i "/$HOSTENTRY_NAME/d" /etc/hosts
      echo "$HOSTENTRY_IP $HOSTENTRY_NAME" >> /etc/hosts
      log_and_echo "Updated host entry for $HOSTENTRY_NAME to $HOSTENTRY_IP"
    else
      $VERBOSE && echo "Host entry for $HOSTENTRY_NAME already correct"
    fi
  else
    echo "$HOSTENTRY_IP $HOSTENTRY_NAME" >> /etc/hosts
    log_and_echo "Added host entry: $HOSTENTRY_IP $HOSTENTRY_NAME"
  fi
fi
