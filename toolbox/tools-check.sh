#!/bin/sh
set -eu

tools="nmap nc socat dig whois ping ip tcpdump tshark masscan traceroute openvpn sqlmap nikto whatweb hydra john hashcat yara exiftool binwalk openssl ffuf gobuster httpx nuclei python3 pipx jq rg curl git"
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

# A PATH check alone misses broken libraries and wrong-architecture binaries.
for command in \
  'nmap --version' 'tshark --version' 'hashcat --version' \
  'sqlmap --version' 'nikto -Version' 'whatweb --version' \
  'binwalk --help' 'ffuf -V' 'gobuster --version' \
  'httpx -version -duc' 'nuclei -version -duc'; do
  printf 'Checking %s\n' "$command"
  # Intentional word splitting: every command above is a trusted literal.
  # shellcheck disable=SC2086
  timeout 30 $command >/dev/null
done

echo "Secbox tool check passed."
