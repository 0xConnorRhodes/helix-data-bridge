reset:
	ruby tests/reset_state.rb
	ruby server.rb

local-build:
	docker build -t helix-dev -f deploy/Containerfile .

local-run:
	docker run -it --rm -p 80:80 helix-dev /bin/sh

pull-test:
	docker pull ghcr.io/0xconnorrhodes/helix-data-bridge:latest
	docker run -it --rm -p 80:80 ghcr.io/0xconnorrhodes/helix-data-bridge
