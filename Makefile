.PHONY: setup build shell check raw vpn config audit test clean

COMPOSE = docker compose
SECBOX_UID ?= $(shell id -u)
SECBOX_GID ?= $(shell id -g)
export SECBOX_UID SECBOX_GID

setup:
	@test "$(SECBOX_UID)" != 0 || (echo "Run make as a regular user, without sudo." >&2; exit 1)
	mkdir -p work labs scripts wordlists

build: setup
	$(COMPOSE) build --pull

shell: setup
	$(COMPOSE) run --rm secbox

check: setup
	$(COMPOSE) run --rm secbox secbox-check

raw: setup
	$(COMPOSE) -f docker-compose.yml -f docker-compose.raw.yml run --rm secbox

vpn: setup
	@test -n "$(OVPN_FILE)" || (echo "Usage: make vpn OVPN_FILE=/absolute/path/client.ovpn" >&2; exit 1)
	$(COMPOSE) -f docker-compose.yml -f docker-compose.vpn.yml run --rm secbox

export OVPN_FILE

config: setup
	$(COMPOSE) config --quiet

audit:
	trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 secbox:local

test: setup
	sh tests/runtime.sh

clean:
	$(COMPOSE) down --remove-orphans
