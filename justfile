reset:
	ruby tests/reset_state.rb
	ruby server.rb

build:
	docker build -t helix-dev -f deploy/Containerfile .

run:
	docker run -it --rm  helix-dev /bin/sh
