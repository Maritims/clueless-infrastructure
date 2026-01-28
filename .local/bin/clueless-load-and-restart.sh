#!/usr/bin/env bash
set -euo pipefail

INCOMING="$HOME/.local/share/podman/incoming-images"
PROCESSED="$HOME/.local/share/podman/processed-images"

mkdir -p "$PROCESSED"

declare -A updated_images=()

for tar in "$INCOMING"/*.tar; do
    [ -e "$tar" ] || continue

    # Basic upload-complete guard
    sleep 2

    echo "Loading image from $tar"
    output=$(podman load --input "$tar")

    # Example output:
    # Loaded image(s): quay.io/example/myapp:latest
    while read -r img; do
        updated_images["$img"]=1
    done < <(echo "$output" | awk '/Loaded image/{print $NF}')

    mv "$tar" "$PROCESSED/"
done

# No images loaded → nothing to do
[ "${#updated_images[@]}" -eq 0 ] && exit 0

echo "Updated images:"
printf '  %s\n' "${!updated_images[@]}"

# Find containers using updated images
mapfile -t containers < <(
    podman ps --format '{{.ID}} {{.Image}}' |
    while read -r cid image; do
        [[ -n "${updated_images[$image]+x}" ]] && echo "$cid"
    done
)

# Restart affected containers
for cid in "${containers[@]}"; do
    echo "Restarting container $cid"
    podman restart "$cid"
done