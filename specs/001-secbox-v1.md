# Secbox V1 specification

## Outcome

A reproducible security toolbox that starts on demand, contains a practical assessment toolchain, runs non-root, and is restrictive by default.

## Problem and users

The current image has useful basics but grants `SYS_ADMIN` and `NET_ADMIN`, making its sandbox claim unsafe. The primary user is an authorised security practitioner working on labs and client-approved targets.

## Scope

- Hardened Compose profile with least privilege and resource limits
- Separate opt-in VPN privilege override
- Network, web, credential and analysis tools
- Pinned Go tool versions and multi-stage build
- Repeatable Make commands, documentation, smoke test and CI vulnerability scan

## Exclusions

- Malware detonation or kernel exploit isolation
- GUI tools, full Kali Linux, Docker socket access and host networking
- Automatic VPN client selection and credentials
- Bundled wordlists or Nuclei templates

## Architecture

Debian Trixie provides stable packaged tools. A Go builder compiles four version-pinned tools; only their binaries enter the runtime image. Compose drops all capabilities, grants none by default, makes the root filesystem read-only and exposes four explicit workspace mounts. An explicit root raw profile adds `NET_RAW` and `DAC_OVERRIDE`; the root VPN profile additionally adds TUN and `NET_ADMIN`.

## Content and data

Assessment output lives in `work/`. Labs, scripts and wordlists are read-only. Home and temporary data are ephemeral tmpfs mounts. No secrets are committed.

## Risks

- Containers share the host kernel and are not equivalent to VMs.
- Root raw/VPN modes expose additional capabilities and may produce root-owned workspace files.
- Debian packages are rebuilt from the current Trixie repositories.
- Security tools may trigger endpoint or network controls.

## Acceptance criteria

1. The default service runs as a configurable non-root UID/GID (1000 by default) and never as root.
2. The default service has a read-only root, `no-new-privileges`, bounded processes, CPU and memory.
3. The default service drops all capabilities and grants none by default.
4. `NET_ADMIN` and `/dev/net/tun` appear only in the VPN override.
5. `secbox-check` verifies every documented bundled tool.
6. Compose configuration validates and the image builds in CI.
7. CI fails on fixed HIGH/CRITICAL image vulnerabilities and verifies signed publication.

## Verification plan

Run Compose config validation, Dockerfile build, `secbox-check`, static configuration assertions and a cold diff review.

## Rollout and rollback

Merge as one coherent commit on `main`. Roll back by reverting that commit; existing files in `work/` are unaffected.
