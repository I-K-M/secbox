#!/bin/sh
set -eu

tools="nmap nc socat dig whois ping ip tcpdump tshark masscan sqlmap nikto whatweb hydra john hashcat yara exiftool binwalk openssl ffuf gobuster httpx nuclei python3 pipx jq rg curl git"
missing=0

for tool in $tools; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "missing: $tool" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "Secbox tool check passed."
