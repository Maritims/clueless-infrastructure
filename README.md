# clueless-infrastructure

This repository contains the Podman configurations and bash scripts for adding and removing websites.

## Installation
Enter the directory in which you cloned this repository and perform the following commands:
```bash
chmod +x install.sh
./install.sh
```

## First time usage
Perform the following steps after installing for the first time or after migrating to a different machine:

1. Enable the services using systemctl:
    ```bash
    systemctl --user daemon-reload
    systemctl --user enable certbot-renew
    systemctl --user enable certbot-renew.timer
    systemctl --user enable nginx
    systemctl --user enable clueless-website```
    ```
2. Generate certificates using certbot:
    ```bash
   podman run --rm -it \
     --name certbot-init \
     --network host \
     -v certbot_certs:/etc/letsencrypt:Z \
     docker.io/certbot/certbot \
     certonly \
     --standalone \
     -d clueless.no \
     -d www.clueless.no \
     --email maritim@gmail.com \
     --agree-tos \
     --non-interactive
   ```

## Usage
Start the services using systemctl:
```bash
systemctl --user enable nginx
systemctl --user start nginx
systemctl --user enable clueless-website
systemctl --user start clueless-website
```
