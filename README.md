# Secbox

Disposable, non-root security toolbox for authorised labs and assessments.

## Security model

The default profile drops every Linux capability and restores only `NET_RAW`, which Nmap and ping need for raw packets. The root filesystem is read-only, privilege escalation is blocked, and CPU, memory and process limits are applied. Project data is isolated in explicit mounts. The Docker socket and host network are never exposed.

Docker containers share the host kernel: Secbox reduces risk but is not a virtual-machine security boundary. Use a dedicated VM for hostile samples, exploit development, untrusted kernel code or high-risk malware analysis.

## Quick start

Requirements: Docker Engine with Compose v2 and GNU Make.

```bash
make build
make check
make shell
```

Directories are created by `make setup`:

- `/work`: writable output and project files
- `/labs`: read-only lab material
- `/scripts`: read-only helper scripts
- `/wordlists`: read-only local wordlists

## Included tools

- Network: Nmap, Netcat, Socat, Masscan, tcpdump, tshark, dig, whois, traceroute
- Web: ffuf, Gobuster, Nuclei, httpx, SQLMap, Nikto, WhatWeb
- Credentials: Hydra, John the Ripper, Hashcat
- Analysis: YARA, ExifTool, binwalk, OpenSSL
- Runtime: Python 3, pipx, Git, curl, jq, ripgrep

Run `secbox-check` inside the container to verify the toolchain.

## VPN profile

The default container has no `NET_ADMIN`. It is added only by the explicit VPN override:

```bash
make vpn OVPN_FILE=/absolute/path/lab.ovpn
```

The profile mounts only that file and `/dev/net/tun`. Start OpenVPN from the shell with `sudo`-free `openvpn --config /vpn/client.ovpn`; the required network capability exists only in this profile.

## Wordlists and templates

Keep large or frequently updated datasets outside the image:

```bash
git clone --depth 1 https://github.com/danielmiessler/SecLists.git wordlists/SecLists
docker compose run --rm secbox nuclei -update-templates
```

The Nuclei update command needs a writable home. Secbox provides an ephemeral in-memory home, so updates disappear when the container exits. Bind a trusted directory explicitly if persistence is required.

## Usage policy

Use Secbox only on systems you own or have explicit permission to test. The operator remains responsible for scope, rate limits, data handling and applicable law.

## Maintenance

Builds use pinned versions for Go tools. Debian packages receive the versions currently available from Debian Bookworm during rebuild. CI builds the image, runs the tool check and scans the result for vulnerabilities.
