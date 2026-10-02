# Secbox V2 — cross-platform professional toolbox specification

> **Unimplemented proposal.** This historical catalogue proposal is not the current runtime contract. Follow the README and V1 specification for shipped behavior. The current default grants no capabilities; raw networking and VPN require explicit root profiles.

## Outcome

Secbox runs consistently from Linux and Windows hosts and provides a curated, verified security assessment toolchain without becoming a full Kali Linux distribution.

## Users and operating model

The primary user is an authorised security practitioner working on labs, training environments and explicitly approved targets. Docker remains the portability boundary: the container is Linux-based on every host, while host-facing commands and documentation must work with Docker Engine on Linux and Docker Desktop on Windows.

## Scope

- First-class Linux and Windows host instructions
- Direct Docker Compose commands that do not require GNU Make
- Optional Make shortcuts for Linux, macOS, WSL and environments where GNU Make is installed
- Linux/amd64 and Linux/arm64 image builds
- A curated professional catalogue covering network, web, discovery, code, secrets, credentials and lightweight analysis
- Bundled SecLists at a documented, pinned revision
- Version-pinned tools installed through reproducible build stages where practical
- A smoke test that verifies every documented bundled tool and dataset
- CI validation of Compose, image builds, runtime restrictions and the complete tool catalogue
- Existing least-privilege and opt-in VPN security model

## Exclusions

- Native Windows binaries or a Windows container image
- A full Kali Linux replacement
- GUI applications
- Wireless auditing requiring direct hardware access
- Malware detonation, kernel exploit isolation or hostile-sample analysis
- Active Directory lab suites and large specialist frameworks
- Docker socket access, privileged containers or host networking
- Automatic attack execution

## Supported hosts and architectures

### Hosts

- Linux with Docker Engine and Docker Compose v2
- Windows 10/11 with Docker Desktop using Linux containers
- WSL2 may use either Docker Desktop integration or a locally configured Docker Engine

The supported interface is Docker Compose. GNU Make is a convenience layer, not a requirement.

### Architectures

- linux/amd64
- linux/arm64

Every bundled binary must either be built from source in a multi-platform builder stage or installed from a repository/package source that supports both target architectures. Tools without viable arm64 support must not silently break the arm64 build.

## Tool catalogue

### Existing baseline retained

- Network: Nmap, Netcat, Socat, Masscan, tcpdump, tshark, dig, whois, traceroute
- Web: ffuf, Gobuster, Nuclei, httpx, SQLMap, Nikto, WhatWeb
- Credentials: Hydra, John the Ripper, Hashcat
- Analysis: YARA, ExifTool, binwalk, OpenSSL
- Runtime: Python 3, pipx, Git, curl, jq, ripgrep

Hashcat is already part of V1 and remains mandatory.

### Additions

- TLS assessment: testssl.sh
- Static analysis: Semgrep
- Wordlists and payloads: SecLists
- Discovery and reconnaissance: subfinder, dnsx, naabu, Katana, gau, Amass
- Secret detection: Gitleaks
- Container and filesystem scanning: Trivy
- Lightweight steganography inspection: Steghide

### Dataset placement

- SecLists is bundled read-only at `/opt/seclists`
- `/wordlists` remains available for user-owned wordlists
- A stable convenience symlink `/usr/share/seclists` points to `/opt/seclists`
- The SecLists source revision is pinned at build time and documented through OCI labels or a version manifest

## Build architecture

The Dockerfile uses focused builder stages:

1. Go builder for Go-based tools
2. Python/pipx stage or controlled virtual environment for Semgrep
3. Fetch stages for testssl.sh and SecLists at immutable revisions
4. Debian Bookworm runtime containing only required runtime files and packaged tools

Remote assets must be pinned to immutable tags, commits or release versions. Release archives must be checksum-verified when the upstream publishes checksums. No installer may execute an unpinned remote shell script.

A generated or maintained version manifest records the source/version of every non-Debian tool.

## Runtime architecture and security

The V1 defaults remain mandatory:

- UID/GID 1000
- Read-only root filesystem
- `no-new-privileges`
- Drop all Linux capabilities
- Add only `NET_RAW` in the default profile
- Bound CPU, memory and process count
- Writable project data only through explicit mounts and tmpfs
- No Docker socket
- No host networking

The VPN override alone may add `NET_ADMIN` and `/dev/net/tun`.

Tools that need writable caches must use the ephemeral home or `/tmp`. SecLists and application binaries remain read-only.

## Cross-platform command interface

README examples must include direct commands usable from PowerShell and POSIX shells:

- Create workspace directories
- Build the image
- Run the tool check
- Open an interactive shell
- Start with the VPN override

Path-sensitive VPN examples must document PowerShell and POSIX syntax separately. The Compose files must avoid host-specific path assumptions beyond an explicitly supplied absolute VPN path.

The Makefile remains supported but must only wrap the canonical Compose commands.

## Verification

### Static assertions

CI checks that:

- The default Compose service drops all capabilities and adds only `NET_RAW`
- `NET_ADMIN` and the TUN device exist only in the VPN override
- The service runs as 1000:1000
- The root filesystem is read-only
- Host networking, privileged mode and Docker socket mounts are absent
- Every README-listed bundled tool is represented in the smoke check

### Runtime smoke test

`secbox-check` verifies commands without performing scans. It must check:

- Every executable in the catalogue
- `testssl.sh --version` or a safe equivalent
- Semgrep availability
- Hashcat availability
- SecLists exists at both documented paths and contains representative files
- Architecture-appropriate binaries execute successfully
- The version manifest exists and is readable

The script returns non-zero and names every missing or unusable component.

### CI matrix

- Compose configuration validation
- linux/amd64 build and smoke test
- linux/arm64 build at minimum through Buildx; runtime smoke test under emulation when stable
- Image vulnerability scan failing on fixed critical vulnerabilities
- Shell syntax/lint checks for project scripts
- Documentation/catalogue consistency checks

GitHub-hosted Linux CI validates the Linux container contract. Windows host compatibility is validated through host-neutral Compose configuration and documented PowerShell commands; a Windows runner is not required because the image itself remains a Linux container.

## Error handling

- Unsupported architectures fail during the build with a clear message
- Missing downloads, checksum mismatches or unavailable pinned revisions fail the build
- Missing tools or datasets fail `secbox-check` with an itemised report
- VPN startup without an absolute profile path fails before container launch
- Cross-platform instructions must avoid commands available only in Bash unless clearly marked as POSIX-specific

## Documentation

The README must state clearly:

- Secbox supports Linux and Windows hosts
- The container itself is Linux-based
- Docker and Compose requirements for each host
- GNU Make is optional
- Exact included-tool catalogue
- SecLists locations
- PowerShell and POSIX quick starts
- Default and VPN security boundaries
- Rebuild/update policy for pinned tools and Debian packages
- Authorised-use policy

## Acceptance criteria

1. A Linux user can build, check and enter Secbox using documented direct Compose commands.
2. A Windows PowerShell user can perform the same flow through Docker Desktop without GNU Make.
3. The image builds for linux/amd64 and linux/arm64.
4. Hashcat remains installed and verified.
5. testssl.sh, Semgrep and SecLists are installed, documented and verified.
6. All additional V2 tools are installed, documented and verified.
7. SecLists is available read-only at `/opt/seclists` and `/usr/share/seclists`.
8. The default runtime retains V1 least-privilege controls.
9. VPN-only privileges do not leak into the default profile.
10. CI detects a missing documented tool, missing dataset, invalid Compose configuration or fixed critical image vulnerability.
11. No unpinned remote installer script is executed during the build.
12. README and smoke-test catalogues remain consistent.

## Rollout and rollback

Implement V2 in reviewable commits grouped by build/toolchain, cross-platform interface, verification and documentation. Existing `work/`, `labs/`, `scripts/` and user `wordlists/` data remain outside the image and are unaffected.

Rollback is performed by reverting the V2 commits or selecting the previous image tag. No data migration is required.
