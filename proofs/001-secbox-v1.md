# Secbox validated delivery

Validated on 2026-10-02. This record describes a completed build, not a guarantee about later commits or vulnerability databases.

## Source and execution evidence

- Reviewed change: [PR #1](https://github.com/I-K-M/secbox/pull/1).
- Merged commit: `c72b78f18688bb039e3f35204d1523f2880cc0a6`.
- [Main workflow run](https://github.com/I-K-M/secbox/actions/runs/36997976810): all required checks and signed publication passed.
- Signed multi-platform image: `ghcr.io/i-k-m/secbox@sha256:daa3be5de21a63b32043ed4d3ce7d9ca2407bc1dbd97e99299d1d43f80887a5f`.

## Verified behavior

| Boundary | Actual check |
|---|---|
| Default user and permissions | Non-root, no effective/bounding capabilities, no-new-privileges |
| Filesystem | Protected paths reject writes; workspace, home and temporary paths allow writes |
| Raw networking | Raw socket denied by default and allowed only in opt-in profiles |
| VPN | Configuration mounted read-only and TUN interface creation succeeds |
| Toolchain | Executable checks, representative commands, local Nmap/httpx/ffuf/Gobuster HTTP smoke tests |
| Architectures | Native Linux amd64 and arm64 builds and runtime tests |
| Vulnerabilities | Full reports retained; fixable HIGH/CRITICAL findings block delivery |
| Supply chain | Both platform signatures and CycloneDX attestations verified; multi-platform index signature verified |

The run retains `source-scan`, `image-reports-*` and `signature-evidence` artifacts for the periods documented in [CI policy](../docs/ci.md). Artifact retention is finite; the immutable digest and source/run links are recorded here for traceability.

## Limits and rollback

Tests use a loopback fixture and create TUN without contacting a VPN server. They do not certify external routing, DNS integration, every tool feature, Windows host behavior or a malware isolation boundary. Anonymous GHCR access and repository protection are administrator settings, not verified runtime controls.

To roll back, select a previously verified image digest and compatible Compose revision. Reverting code does not remove published images or change existing workspace data. Scan an older image again before using it.
