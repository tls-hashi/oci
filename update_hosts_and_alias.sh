#!/bin/bash

# Get the reverse_proxy_ip from terraform outputs
REVERSE_PROXY_IP=$(terraform output -raw reverse_proxy_ip 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$REVERSE_PROXY_IP" ]; then
  echo "Error: Could not retrieve reverse_proxy_ip from terraform outputs."
  exit 1
fi
echo "Obtained reverse_proxy_ip: $REVERSE_PROXY_IP"

# Prepare hosts entry
HOSTS_ENTRY="${REVERSE_PROXY_IP} reverse-proxy"

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

# Check current IP for reverse-proxy in /etc/hosts
CURRENT_IP=$(grep "reverse-proxy" /etc/hosts | awk '{print $1}')

if [ "$CURRENT_IP" != "$REVERSE_PROXY_IP" ]; then
  if grep -q "reverse-proxy" /etc/hosts; then
    $SUDO sed -i.bak "/reverse-proxy/c\\$HOSTS_ENTRY" /etc/hosts
    echo "Updated /etc/hosts entry for reverse-proxy."
  else
    echo "$HOSTS_ENTRY" | $SUDO tee -a /etc/hosts >/dev/null
    echo "Added /etc/hosts entry for reverse-proxy."
  fi
else
  echo "/etc/hosts entry for reverse-proxy is already up to date."
fi

# Set the alias for connecting to the reverse proxy
SSH_USER="ubuntu"
ALIAS_CMD="alias ocloud='ssh -i ~/.ssh/id_rsa ${SSH_USER}@reverse-proxy'"

# Update ~/.zshrc: remove any existing ocloud alias and append the new alias
if grep -q "alias ocloud=" ~/.zshrc; then
  sed -i.bak "/alias ocloud=/d" ~/.zshrc
fi
echo "$ALIAS_CMD" >> ~/.zshrc
echo "Updated ~/.zshrc with the ocloud alias."

echo "Please run 'source ~/.zshrc' to apply changes."