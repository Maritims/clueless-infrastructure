#!/bin/bash

# Usage: ./provision-site.sh domain.com
DOMAIN=$1
EMAIL="maritim@gmail.com" # Change this!
CONTAINER_NAME="${DOMAIN//./-}-site"
BASE_DIR="$HOME/containers"
PROXY_CONF_DIR="$HOME/proxy-configs"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 domain.com"
    exit 1
fi

echo "--- Provisioning $DOMAIN ---"

# 1. Create directory structure
mkdir -p "$BASE_DIR/$DOMAIN/config" "$BASE_DIR/$DOMAIN/data"

# 2. Create Internal Nginx Config
cat <<EOF > "$BASE_DIR/$DOMAIN/config/default.conf"
server {
    listen 80;
    server_name _;
    location / {
        root   /usr/share/nginx/html;
        index  index.html;
        try_files \$uri \$uri/ =404;
    }
}
EOF

# 3. Create placeholder index.html
echo "<h1>Welcome to $DOMAIN</h1>" > "$BASE_DIR/$DOMAIN/data/index.html"

# 4. Create the Quadlet Container file
cat <<EOF > "$HOME/.config/containers/systemd/$DOMAIN.container"
[Unit]
Description=Container for $DOMAIN

[Container]
ContainerName=$CONTAINER_NAME
Image=docker.io/nginx:stable-alpine
Network=web-gateway.network
Volume=$BASE_DIR/$DOMAIN/config/default.conf:/etc/nginx/conf.d/default.conf:ro
Volume=$BASE_DIR/$DOMAIN/data:/usr/share/nginx/html:ro

[Install]
WantedBy=default.target
EOF

# 5. Run Certbot (Webroot mode)
echo "--- Requesting SSL Certificate ---"
podman run --rm -it \
  -v certbot_certs:/etc/letsencrypt:Z \
  -v certbot_webroot:/var/www/html:Z \
  docker.io/certbot/certbot certonly --webroot \
  -w /var/www/html \
  -d "$DOMAIN" -d "www.$DOMAIN" \
  --email "$EMAIL" --agree-tos --non-interactive

# 6. Create Proxy Config
cat <<EOF > "$PROXY_CONF_DIR/$DOMAIN.conf"
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://\$host\$request_uri; }
}

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://$CONTAINER_NAME:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 7. Reload everything
echo "--- Activating Services ---"
systemctl --user daemon-reload
systemctl --user start "$DOMAIN.service"
systemctl --user kill -s SIGHUP nginx-proxy.service

echo "Done! Visit https://$DOMAIN"
