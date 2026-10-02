# Secbox

**A hardened security toolbox with a verified DevSecOps delivery pipeline.**

[![Security CI](https://github.com/I-K-M/secbox/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/I-K-M/secbox/actions/workflows/security.yml)

A disposable CLI toolbox for authorised security labs and assessments. Runs in a restricted Docker container; project files stay in explicit workspace mounts.

The repository demonstrates container hardening and a CI supply chain: native amd64/arm64 builds, runtime security tests, source and image scans, CycloneDX SBOMs and keyless image signing. It does not deploy infrastructure or require cloud credentials.

## Verified delivery

The [validated delivery](proofs/001-secbox-v1.md) records the tested commit, native architecture checks and immutable signed image digest. See the [security architecture](docs/architecture.md) for runtime and CI trust boundaries.

## Quick start

Requirements: Docker Engine with Compose v2 on Linux, or Docker Desktop with Linux containers on Windows/macOS. Images target Linux amd64 and arm64. GNU Make is optional.

```bash
git clone https://github.com/I-K-M/secbox.git
cd secbox
mkdir -p work labs scripts wordlists
docker compose build --pull
docker compose run --rm secbox secbox-check
docker compose run --rm secbox
```

On Linux, match the container to your account before running Compose so `/work` is writable:

```bash
export SECBOX_UID="$(id -u)" SECBOX_GID="$(id -g)"
```

With Make, these IDs are set automatically: `make build`, `make check`, `make shell`. Run Make as a regular user, without `sudo`.

In PowerShell, replace the `mkdir` line with:

```powershell
New-Item -ItemType Directory -Force -Path work,labs,scripts,wordlists | Out-Null
```

The Docker Compose commands are identical. Windows/macOS use the default container UID/GID 1000.

| Container path | Purpose | Access |
|---|---|---|
| `/work` | Project files and assessment output | Writable, persistent |
| `/labs` | Lab material | Read-only |
| `/scripts` | Helper scripts | Read-only |
| `/wordlists` | Local datasets | Read-only |
| `/tmp`, `/home/secbox` | Temporary files, caches, shell history | Writable tmpfs, discarded on exit |

## Security profiles

| Profile | User | Capabilities | Use |
|---|---|---|---|
| Default | Non-root | None | Web tools, TCP connect scans, offline analysis |
| Raw | Container root | `NET_RAW`, `DAC_OVERRIDE` | SYN scans and packet capture inside the container network |
| VPN | Container root | `NET_RAW`, `NET_ADMIN`, `DAC_OVERRIDE` | OpenVPN and raw networking inside the VPN |

All profiles retain a read-only root filesystem, `no-new-privileges`, a private bridge network, and CPU/memory/process limits. They do not mount the Docker socket or use host networking. Setuid/setgid bits are removed from the image.

The root modes are explicit exceptions. Adding `NET_RAW` to a non-root Compose service does not reliably provide effective raw-socket permissions; file capabilities cannot fix that under `no-new-privileges`. `DAC_OVERRIDE` lets these root modes write the regular user's workspace and ephemeral home; read-only mounts remain protected. The runtime tests exercise actual socket creation and TUN creation rather than checking YAML alone.

Docker shares the host kernel. Use a dedicated VM for hostile samples or kernel exploit work. This toolbox is not a malware sandbox.

### Normal TCP scan

```bash
docker compose run --rm secbox nmap -sT -Pn -p 80,443 YOUR_AUTHORISED_TARGET
```

### Raw networking

```bash
docker compose -f docker-compose.yml -f docker-compose.raw.yml run --rm secbox
```

Or `make raw`. Captures see the container's network namespace, not host interfaces. Root modes may create root-owned files in `/work` on Linux.

### VPN

Linux requires an available `/dev/net/tun`; Docker Desktop support depends on its Linux VM. Set the absolute path of a trusted OpenVPN configuration:

```bash
export OVPN_FILE="/absolute/path/lab.ovpn"
docker compose -f docker-compose.yml -f docker-compose.vpn.yml run --rm secbox
```

PowerShell:

```powershell
$env:OVPN_FILE = (Resolve-Path .\lab.ovpn).Path
docker compose -f docker-compose.yml -f docker-compose.vpn.yml run --rm secbox
```

Inside the container, run `openvpn --config /vpn/client.ovpn`. Or use `make vpn OVPN_FILE=/absolute/path/lab.ovpn` on Linux. External certificates/credentials referenced by the configuration need their own explicit mount or a path under `/work`. Host DNS integration is not automatic; review the VPN's DNS and routing requirements.

## Included tools

| Area | Tools |
|---|---|
| Network | Nmap, Netcat, Socat, Masscan, tcpdump, tshark, dig, whois, ping, ip, traceroute, OpenVPN |
| Web | ffuf, Gobuster, Nuclei, httpx, SQLMap, Nikto, WhatWeb |
| Credentials | Hydra, John the Ripper, Hashcat |
| Analysis | YARA, ExifTool, binwalk, OpenSSL |
| Runtime | Python 3, pipx, Git, curl, jq, ripgrep |

`secbox-check` checks every listed executable and launches representative tools to catch missing libraries and architecture errors. GPU passthrough and headless browser dependencies are not bundled.

Go tools are compiled from pinned upstream versions using a pinned compiler image and a shared, locked `go.mod`/`go.sum` graph. This graph upgrades vulnerable upstream transitive dependencies; the binaries therefore include reviewed dependency patches beyond their upstream releases. The HTTP smoke tests exercise those builds. Nikto uses release 2.6.1 at commit `d201dac320fc5187eac75e723dd07a716196ec5a`. Debian packages come from the current Trixie repositories at build time. Base images, Go modules and action pins are reviewed through Dependabot.

### Wordlists and templates

Datasets remain outside the image:

```bash
git clone --depth 1 https://github.com/danielmiessler/SecLists.git wordlists/SecLists
```

To use Nuclei, update and scan in the same container session:

```bash
nuclei -update-templates
nuclei -u https://YOUR_AUTHORISED_TARGET -duc
```

Templates and caches in the home directory disappear on exit. Local templates can instead be stored under `/work` and supplied with `-t`. Updated templates are separate from the signed image's toolchain.

## CI and signed images

Every PR and `main` push runs ShellCheck, actionlint, Compose validation, Trivy repository scans, native builds for both architectures, tool smoke tests, and runtime tests of each profile. Image scanning checks Debian packages and embedded Go dependencies. Fixed HIGH/CRITICAL image vulnerabilities block the pipeline; the complete report also retains unfixed findings.

Only a successful `main` push can publish to GHCR. The publication job receives no repository checkout. It loads the exact tested image archives, verifies their checksums, signs each platform image and its SBOM with Cosign, creates a multi-platform index and verifies its signature. PR jobs have read-only permissions and no OIDC or registry write access.

The successful run summary provides an immutable `ghcr.io/i-k-m/secbox@sha256:...` reference. Verify before using it:

```bash
cosign verify \
  --certificate-identity 'https://github.com/I-K-M/secbox/.github/workflows/security.yml@refs/heads/main' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  ghcr.io/i-k-m/secbox@sha256:REPLACE_WITH_VERIFIED_DIGEST
```

Then set `SECBOX_IMAGE` to that exact reference and use `docker compose pull` followed by `docker compose run --rm secbox`. See [CI policy](docs/ci.md) for SBOM verification, findings and repository protection settings.

## Contributing and maintenance

`make test` runs the container tests on a Linux Docker host with `/dev/net/tun`. Tests scan only a temporary loopback HTTP server; they do not contact external assessment targets.

Dependabot opens weekly PRs for action pins and base images. A weekly scheduled rebuild scans fresh OS packages against the current vulnerability database. Upstream tool versions and scanner versions are explicit maintenance tasks.

See [contributing](CONTRIBUTING.md), [security reporting](SECURITY.md), and [changes](CHANGELOG.md). The V2 documents under `specs/` and `docs/superpowers/plans/` describe planned catalogue additions; tools are bundled only when listed above.

Use Secbox only on systems you own or have explicit permission to test. Keep assessment output, captures, VPN credentials and client material out of Git.
