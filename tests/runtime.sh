#!/bin/sh
set -eu

mkdir -p work labs scripts wordlists
docker compose config --quiet
docker compose run --rm -T secbox secbox-check
docker compose run --rm -T secbox python3 - default < tests/runtime.py
docker compose -f docker-compose.yml -f docker-compose.raw.yml run --rm -T secbox python3 - raw < tests/runtime.py

# Verify the VPN privilege boundary without contacting a VPN or external target.
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
printf '# CI fixture, no credentials or remote endpoint\n' > "$temporary/client.ovpn"
export OVPN_FILE="$temporary/client.ovpn"
docker compose -f docker-compose.yml -f docker-compose.vpn.yml config --quiet
docker compose -f docker-compose.yml -f docker-compose.vpn.yml run --rm -T secbox python3 - vpn < tests/runtime.py
