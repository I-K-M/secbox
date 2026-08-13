# Secbox V1 proof pack

## Summary

Replaced the broad-capability prototype with a least-privilege, non-root toolbox and an explicit VPN override.

## Links

- Spec: `specs/001-secbox-v1.md`
- Ticket: `tickets/001-secbox-v1/001-harden-and-package.md`

## Changed behavior

- Default capability set changed from `NET_ADMIN` plus `SYS_ADMIN` to `NET_RAW` only.
- Root filesystem is now read-only and resources are bounded.
- Tools are grouped into a reproducible multi-stage image with a smoke test.
- VPN privileges are isolated in an explicit override.
- CI now validates, builds, tests and scans the image.

## Commands and results

- Static capability assertions passed: no `SYS_ADMIN` or `NET_ADMIN` in the default profile; `NET_ADMIN` and TUN occur only in the VPN override.
- Shell syntax, Make command expansion and `git diff --check` passed.
- All four pinned Go release tags were verified against their upstream repositories.
- Docker runtime validation was unavailable in the publishing environment (`docker: command not found`); GitHub Actions performs Compose validation, the full image build, tool smoke test and Trivy scan on `main`.

## Review

Cold review checks privilege boundaries, mount access, version pinning, documentation accuracy and rollback behavior.

## Migrations and environment

No data migration. Docker Compose v2 and Make are required. Existing ignored workspace data remains local.

## Known limitations

Docker is not a VM boundary. Wordlists and templates are not bundled. VPN client choice remains lab-specific.

## Rollback

Revert the V1 commit. Workspace data under `work/` remains untouched.

## Human checks

Confirm authorised target scope before every assessment and test VPN routing against a lab endpoint before use.
