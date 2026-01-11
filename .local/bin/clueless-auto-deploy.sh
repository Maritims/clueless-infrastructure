#!/usr/bin/env bash
set -euo pipefail

IMAGE_FILE="$1"
CONTAINER_NAME="$2"

echo "Deploying new image from $IMAGE_FILE"

# Load image into Podman
podman image load -i "$IMAGE_FILE"

# Restart systemd-managed container
systemctl --user restart "$CONTAINER_NAME".service

# Flytt image til arkiv for å unngå dobbel-trigger
mkdir -p ~/incoming-images/archive
mv "$IMAGE_FILE" ~/incoming-images/archive/

echo "Deployment complete."

