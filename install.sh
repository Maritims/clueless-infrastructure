#!/usr/bin/bash
#
# Installs the clueless-infrastructure configurations and scripts.

shopt -s nullglob

# Local scripts
mkdir -p ~/.local/bin
for f in .local/bin/*; do
	if [ ! -e ~/.local/bin/$(basename "$f") ]; then
		echo "Creating symlink: $f"
		ln -sf "$PWD/$f" ~/.local/bin/
	else
		echo "Symlink already exists: $f"
	fi
done

# Podman directories
mkdir -p ~/.local/share/podman
for f in .local/share/podman/*; do
	if [ ! -e ~/.local/share/podman/$(basename "$f") ]; then
		echo "Creating symlink: $f"
		ln -sf "$PWD/$f" ~/.local/share/podman/
	else
		echo "Symlink already exists: $f"
	fi
done

# Podman container files
mkdir -p ~/.config/containers/systemd
for f in .config/containers/systemd/*; do
	if [ ! -e ~/.config/containers/systemd/$(basename "$f") ]; then
		echo "Creating symlink: $f"
		ln -sf "$PWD/$f" ~/.config/containers/systemd/
	else
		echo "Symlink already exists: $f"
	fi
done

# systemd user timers
mkdir -p ~/.config/systemd/user
for f in .config/systemd/user/*; do
	if [ ! -e ~/.config/systemd/user/$(basename "$f") ]; then
		echo "Creating symlink: $f"
		ln -sf "$PWD/$f" ~/.config/systemd/user/
	else
		echo "Symlink already exists: $f"
	fi
done

# Nginx configuration
if [ ! -e ~/.config/nginx ]; then
	echo "Creating symlink: .config/nginx"
	ln -s "$PWD/.config/nginx" ~/.config/nginx
else
	echo "Symlink already exists: .config/nginx"
fi