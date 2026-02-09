# Makefile for clueless-infrastructure

.PHONY: all links ssl reload
IS_PROD = $(shell [ "$$(hostname)" = "ubuntu-1cpu-1gb-se-sto1" ] && echo "yes" || echo "no")

all: links ssl reload
	@echo "System is fully installed and configured."

links:
	@echo "Creating directory structure..."
	@mkdir -p ~/.local/bin ~/.config/containers/systemd ~/.config/systemd/user ~/.config/nginx

	@echo "Generating ports.env for $(shell hostname)..."
ifeq ($(IS_PROD), yes)
	@echo "NGINX_HTTP_PORT=80" > ~/.config/nginx/ports.env
	@echo "NGINX_HTTPS_PORT=443" >> ~/.config/nginx/ports.env
else
	@echo "NGINX_HTTP_PORT=8080" > ~/.config/nginx/ports.env
	@echo "NGINX_HTTPS_PORT=4430" >> ~/.config/nginx/ports.env
endif

	@echo "Linking Nginx files..."
	@# Link the main config file
	@ln -sf $(PWD)/.config/nginx/nginx.conf ~/.config/nginx/nginx.conf
	@# Link the conf.d directory itself
	@ln -sfn $(PWD)/.config/nginx/conf.d ~/.config/nginx/conf.d

	@echo "Linking scripts and Quadlets..."
	@find .local/bin -type f -exec bash -c 'ln -sf "$(PWD)/$$0" "$(HOME)/$$0" && echo "    -> Linked $$0"' {} \;
	@find .config/containers/systemd -type f -exec bash -c 'ln -sf "$(PWD)/$$0" "$(HOME)/$$0" && echo "    -> Linked $$0"' {} \;

ssl:
	@echo "Checking environment..."
ifeq ($(IS_PROD), yes)
	@echo "Production detected. Checking for real certs..."
	@podman volume inspect certbot_certs >/dev/null 2>&1 || \
		(podman volume create certbot_certs && echo "Created certbot_certs volume")
	@if ! podman run --rm -v certbot_certs:/certs alpine ls /certs/live/clueless.no/fullchain.pem >/dev/null 2>&1; then \
		echo "Certs missing. Attempting Certbot standalone initialization..."; \
		podman run --rm \
			--name certbot-init \
			--network host \
			-v certbot_certs:/etc/letsencrypt:Z \
			docker.io/certbot/certbot \
			certonly --standalone -d clueless.no -d www.clueless.no \
			--email maritim@gmail.com --agree-tos --non-interactive; \
	else \
		echo "Real certs verified."; \
	fi
else
	@echo "Dev environment detected. Checking dummy certs..."
	@podman volume inspect certbot_certs >/dev/null 2>&1 || podman volume create certbot_certs >/dev/null
	@if ! podman run --rm -v certbot_certs:/certs alpine ls /certs/live/clueless.no/fullchain.pem >/dev/null 2>&1; then \
		echo "Generating dev certificates..."; \
		podman run --rm -v certbot_certs:/certs alpine sh -c \
			"mkdir -p /certs/live/clueless.no && apk add --no-cache openssl && \
			openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout /certs/live/clueless.no/privkey.pem \
			-out /certs/live/clueless.no/fullchain.pem \
			-subj '/CN=clueless.no'"; \
	else \
		echo "Dummy certs already exist."; \
	fi
endif

reload:
	@echo "Reloading systemd --user daemon..."
	@systemctl --user daemon-reload
	@echo "To start the stack, run: systemctl --user start nginx.service"

clean:
	@echo "Cleaning up symlinks..."
	@# Remove the nginx config symlink if it points here
	@if [ -L ~/.config/nginx ]; then rm ~/.config/nginx && echo "    -> Removed ~/.config/nginx"; fi

	@# Find and remove symlinks in the target directories that point to this project
	@find ~/.local/bin ~/.config/containers/systemd ~/.config/systemd/user -type l -lname "$(PWD)/*" -delete -print | sed 's/^/    -> Removed /'

	@echo "Reloading systemd to clear generated units..."
	@systemctl --user daemon-reload
	@echo "Cleanup complete. Podman volumes and networks were preserved."