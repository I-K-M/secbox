# Security policy

Security fixes target the current `main` version. Old local or published images do not receive updates automatically; rebuild or select a newly verified digest.

Report a security issue privately through GitHub's **Report a vulnerability** feature when enabled. If it is unavailable, contact the maintainer using the GitHub profile to agree on a private channel. Do not include secrets or client data in public issues.

Include the affected commit/image digest, host OS and Docker version, selected Compose profile, expected boundary and a minimal reproduction using local fixtures. Container escapes, unexpected privilege grants, writable protected mounts, credential exposure and supply-chain verification failures are in scope.

Secbox is for authorised assessment work. Containers share the host kernel and the root opt-in profiles have more authority within their network namespace. Secbox does not provide a VM or malware-detonation boundary. See the README for the exact profile privileges and CI policy for vulnerability handling.
