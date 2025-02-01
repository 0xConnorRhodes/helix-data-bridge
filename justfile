reset:
	ruby tests/reset_state.rb
	ruby server.rb

build:
	docker build -t helix-dev -f deploy/container-build/Containerfile .

run:
    docker run -d --name helix \
    -p 80:80 \
    -e ADMIN_USERNAME=admin \
    -e ADMIN_PASSWORD=changeme \
    helix-dev

exec:
	docker exec -it helix /bin/sh

pull-test:
	docker pull ghcr.io/0xconnorrhodes/helix-data-bridge:latest
	docker run -it --rm -p 80:80 ghcr.io/0xconnorrhodes/helix-data-bridge
