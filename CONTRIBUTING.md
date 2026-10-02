# Contributing

Open a PR with the concrete change, its purpose and how you verified it. Keep the tool catalogue curated: a new tool needs a pinned source, amd64/arm64 support, a smoke check, runtime dependencies and a documented permission requirement.

For Linux runtime validation:

```bash
make build
make test
```

The tests require Docker Compose v2 and `/dev/net/tun`. They verify non-root operation, effective capabilities, read-only mounts, writable work/cache paths, local TCP scanning and TUN creation. No external target is scanned and no VPN connection is established.

For local linting, run `shellcheck toolbox/*.sh scripts/*.sh tests/*.sh` and `actionlint`. Use `git diff --check` before submitting. CI performs native builds and image vulnerability scans on both architectures; local validation on one architecture does not replace those checks.

Do not commit client data, captures, credentials, private keys or large datasets. Do not add the Docker socket, host networking, privileged mode or broad capabilities to the base profile. New privilege exceptions must be opt-in and covered by an actual runtime test.
