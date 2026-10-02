# Security architecture

Secbox separates assessment tools, build inputs and publication authority. It is a container toolbox, not an application platform or a VM isolation boundary.

## Runtime boundaries

| Profile | Identity and authority | Purpose |
|---|---|---|
| Default | Configurable non-root user; zero capabilities | Web tools, TCP connect scans, offline inspection |
| Raw | Container root; NET_RAW and DAC_OVERRIDE | Raw sockets and workspace access |
| VPN | Container root; raw capabilities plus NET_ADMIN and TUN | OpenVPN and network configuration |

Every profile uses a read-only root filesystem, no-new-privileges, bounded resources and explicit mounts. Labs, scripts and wordlists are read-only; workspace output persists. Home and temporary files are ephemeral. No Docker socket, privileged mode or host network is used.

The host kernel remains shared. Root profiles deliberately increase authority and require operator judgment. Untrusted tools, templates and lab files remain a risk even when their storage is read-only.

## Delivery boundaries

1. Read-only PR jobs validate source and build/test native amd64 and arm64 images on disposable runners.
2. Main repeats those checks on the merged commit. A single aggregate check, `CI passed`, requires both architecture jobs and source validation.
3. The publication job receives tested archives from that run, checks their digests, and alone receives registry write and OIDC permissions. It performs no repository checkout.
4. Cosign signs platform images, attests their SBOMs and signs the multi-platform index. Verification requires the exact main workflow identity and issuer.

Pinned actions, compiler/base-image digests, module checksums and immutable Nikto source constrain build inputs. Debian repositories and vulnerability databases refresh over time: rebuilding a commit is repeatable operationally but is not guaranteed byte-for-byte reproducible. A signed digest identifies the exact delivered artifact.

## Operator responsibilities

Verify the image digest and signing identity, update stale images, review retained vulnerability reports, and use only authorised targets. Keep secrets and assessment data outside Git. Configure main protection and package visibility in GitHub; code-owner declarations alone do not enforce review.

See [CI policy](ci.md), [validated evidence](../proofs/001-secbox-v1.md) and [security reporting](../SECURITY.md).
