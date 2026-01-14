#!/usr/bin/bash
#
# Installs the clueless-infrastructure configurations and scripts.

shopt -s nullglob

# Local scripts
mkdir -p ~/.local/bin
for f in .local/bin/*; do
	echo "Creating symlink: $f"
	ln -sf "$f" "$PWD/.local/bin/"
done

# Podman container files
mkdir -p ~/.config/containers/systemd
for f in .config/containers/systemd/*; do
	echo "Creating symlink: $f"
	ln -sf "$f" "$PWD/.config/containers/systemd/"
done

# systemd user timers
mkdir -p ~/.config/systemd/user
for f in .config/systemd/user/*; do
	echo "Creating symlink: $f"
	ln -sf "$f" "$PWD/.config/systemd/user/"
done

# Nginx configuration
mkdir -p ~/.config/nginx
echo "Creating symlink: .config/nginx/nginx.conf"
ln -sf "$PWD/.config/nginx/nginx.conf" ~/.config/nginx/nginx.conf