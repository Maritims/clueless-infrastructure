#!/bin/bash
DOMAIN=$1
BASE_DIR="$HOME/containers"
PROXY_CONF_DIR="$HOME/proxy-configs"
QUADLET_DIR="$HOME/.config/containers/systemd"

if [ -z "$DOMAIN" ]; then
    echo "Usage: ./remove-site.sh domain.com"
    exit 1
fi

echo "--- WARNING: Removing $DOMAIN ---"
read -p "Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# 1. Stop and remove the Quadlet service
systemctl --user stop "$DOMAIN.service" 2>/dev/null
rm -f "$QUADLET_DIR/$DOMAIN.container"
systemctl --user daemon-reload

# 2. Remove Proxy Config
rm -f "$PROXY_CONF_DIR/$DOMAIN.conf"
systemctl --user kill -s SIGHUP nginx-proxy.service

# 3. Delete Let's Encrypt Certs
podman run --rm -v certbot_certs:/etc/letsencrypt:Z \
  docker.io/certbot/certbot delete --cert-name "$DOMAIN" --non-interactive

# 4. Backup the data folder
BACKUP_PATH="$BASE_DIR/backups/${DOMAIN}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BASE_DIR/backups"
mv "$BASE_DIR/$DOMAIN" "$BACKUP_PATH"

echo "Success. $DOMAIN removed. Files archived to $BACKUP_PATH"
