#!/usr/bin/bash
#
# Installs the clueless-infrastructure configurations and scripts.

shopt -s nullglob

# Local scrcipts
mkdir -p ~/.local/bin
for f in .local/bin/*; do
	echo "Creating symlink: $f"
	ln -sf "$f" ~/.local/bin/
done

# Podman container files
mkdir -p ~/.config/containers/systemd
for f in .config/containers/systemd/*; do
	echo "Creating symlink: $f"
	ln -sf "$f" ~/.config/containers/systemd/
done

# systemd user timers
mkdir -p ~/.config/systemd/user
for f in .config/systemd/user/*; do
	echo "Creating symlink: $f"
	ln -sf "$f" ~/.config/systemd/user/
done
