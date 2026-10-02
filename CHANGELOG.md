# Changelog

## Unreleased

- Repair CI action resolution and pin all actions and base images to immutable commits/digests.
- Refresh Debian, the Go compiler, ffuf, Gobuster, httpx, Nuclei and Nikto.
- Use a non-root, zero-capability default profile; make effective raw/VPN capabilities explicit opt-in profiles.
- Fix executable search paths, actual Docker build-context exclusions, VPN path quoting and workspace ownership configuration.
- Remove setuid/setgid bits and validate read-only mounts, effective capabilities, TCP scans and TUN creation in running containers.
- Add native amd64/arm64 builds, shell/workflow lint, repository secret/config scans and complete image vulnerability inventories.
- Generate platform SBOMs; publish the exact tested images, sign images/SBOMs and verify identities and digests.
- Document supported commands, limits, maintenance, vulnerability handling and required repository settings.
