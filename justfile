reset:
	ruby tests/reset_state.rb
	ruby server.rb

build:
	docker build -t helix-dev -f deploy/container-build/Containerfile .

run-noconfig:
	docker run -it --rm \
	--name helix \
	--hostname helix \
	-p 80:80 \
	-v "$(pwd)/.env:/app/.env" \
	helix-dev

run-with-config:
	docker run -it --rm \
	--name helix \
	--hostname helix \
	-p 80:80 \
	-v "$(pwd)/.env:/app/.env" \
	-v "$(pwd)/devices_config.csv:/app/devices_config.csv" \
	-v "$(pwd)/event_types_config.csv:/app/event_types_config.csv" \
	helix-dev

exec:
	docker exec -it helix /bin/sh

pull-test:
	docker pull ghcr.io/0xconnorrhodes/helix-data-bridge:latest
	docker run -it --rm -p 80:80 ghcr.io/0xconnorrhodes/helix-data-bridge
