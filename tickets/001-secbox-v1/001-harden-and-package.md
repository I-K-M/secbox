# Harden and package Secbox

Parent: `specs/001-secbox-v1.md`

## Outcome

Deliver the complete secured CLI toolbox V1.

## Allowed boundary

Container build, Compose files, Makefile, tool smoke test, CI, documentation and delivery evidence.

## Dependencies

None.

## Acceptance criteria and checks

- All seven parent-spec criteria pass.
- Run `docker compose config --quiet`.
- Build the image and run `secbox-check` when Docker is available.
- Confirm forbidden capabilities are absent from the base Compose file.

## Exclusions

GUI tools, malware sandboxing, host networking, Docker socket and target automation.
