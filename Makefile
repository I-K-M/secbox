.PHONY: setup build shell check vpn config audit clean

COMPOSE = docker compose

setup:
	mkdir -p work labs scripts wordlists

build: setup
	$(COMPOSE) build --pull

shell: setup
	$(COMPOSE) run --rm secbox

check: setup
	$(COMPOSE) run --rm secbox secbox-check

vpn: setup
	@test -n "$(OVPN_FILE)" || (echo "Usage: make vpn OVPN_FILE=/absolute/path/client.ovpn" >&2; exit 1)
	OVPN_FILE=$(OVPN_FILE) $(COMPOSE) -f docker-compose.yml -f docker-compose.vpn.yml run --rm secbox

config: setup
	$(COMPOSE) config --quiet

audit:
	docker scout cves secbox:local

clean:
	$(COMPOSE) down --remove-orphans
