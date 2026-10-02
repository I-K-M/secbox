# CI policy and artifact verification

## Trust boundaries

The workflow uses `pull_request`, never `pull_request_target`. Untrusted PRs build and run only on disposable GitHub-hosted runners. Their token has `contents: read`, checkout does not persist credentials, and no PR job can request an OIDC token or publish packages. Every action is pinned to a full commit SHA. Standalone lint executables are checked against committed SHA-256 values.

On a `main` push, the same checks run again against the actual merged commit. A separate publication job loads image archives produced by those successful jobs in the same run. Artifact download rejects digest mismatches; archive/SBOM checksums are also checked. The publication job does not build the image or execute its code. Only this job has `packages: write` and `id-token: write`.

The keyless certificate must identify exactly:

```text
https://github.com/I-K-M/secbox/.github/workflows/security.yml@refs/heads/main
```

with issuer `https://token.actions.githubusercontent.com`. A valid signature proves control of this workflow identity and integrity of the signed digest. It does not prove that the image is vulnerability-free or that the workflow cannot be maliciously modified.

## Gates and evidence

| Check | Blocking policy | Evidence |
|---|---|---|
| ShellCheck / actionlint | Any lint failure | Job log |
| Trivy filesystem | HIGH/CRITICAL secrets, misconfiguration or dependency findings | `source-scan` artifact, 14 days |
| Native builds | Either architecture fails | Job log |
| Tool/runtime tests | Missing tool, broken representative command or failed boundary test | Job log |
| Trivy image | Fixed HIGH/CRITICAL vulnerabilities | Full `image-reports-*` artifacts, 30 days |
| SBOM generation | Inventory cannot be generated | CycloneDX JSON in image reports |
| Publication | Signature or SBOM attestation verification fails | `signature-evidence` artifact, 90 days |

Image reports include unfixed and lower-severity findings. The blocking gate uses `--ignore-unfixed` only because upstream Debian components may not yet offer a patch; it is not a blanket statement that such vulnerabilities are acceptable. Review those findings when selecting tools and using the image. No vulnerability allowlist or `continue-on-error` is used.

Go dependency scanning reads embedded module versions from the compiled binaries. This repository has no application dependency manifest to review, so an application SAST/Dependency Review job would not replace that scan. Adding application code requires adding the corresponding language checks.

## Verify a platform SBOM

The workflow signs the index and each platform image. SBOM attestations belong to the platform digests, since amd64 and arm64 inventories can differ. Find these in the image index:

```bash
docker buildx imagetools inspect ghcr.io/i-k-m/secbox@sha256:INDEX_DIGEST
cosign verify-attestation \
  --type cyclonedx \
  --certificate-identity 'https://github.com/I-K-M/secbox/.github/workflows/security.yml@refs/heads/main' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  ghcr.io/i-k-m/secbox@sha256:PLATFORM_DIGEST
```

Prefer digest references when running an image. Tags identify commits for convenience but registry tags can be overwritten.

## Repository settings

Workflow files cannot enforce merge protection on their own. In GitHub Settings → Rules → Rulesets, apply a rule to `main` requiring pull requests, the `CI passed` status check, resolved review discussions, and no force push or deletion. Enable code-owner review when another maintainer can review; a sole owner cannot approve their own PR. Keep bypass permissions limited.

Use read-only default Actions permissions and disable Actions creating/approving pull requests unless separately needed. Enable Dependabot alerts and private vulnerability reporting where available. New GHCR packages may require changing package visibility to public before anonymous users can pull or verify them. The workflow does not alter account or repository administrative settings.

## Updating and responding to failures

For a failed action resolution, verify the upstream release and resolve its tag to an actual commit; annotated tag objects are not action commit pins. For an image CVE, inspect `image.json`, identify whether it belongs to Debian, the Go standard library or an embedded module, update the responsible input and rerun both native builds. Do not suppress the scanner to make the badge green.

Base images and upstream source versions are pinned; Debian repository contents are intentionally refreshed during builds. Rebuilds of one commit can therefore have different digests. The published digest, SBOM, revision label and signed workflow identity are the artifact's audit record.
