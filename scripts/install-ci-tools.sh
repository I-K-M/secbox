#!/bin/sh
set -eu

# CI runs this installer on the amd64 lint runner only. Downloaded executables
# are checked against digests committed here, not a mutable remote checksum file.
destination=${1:?Usage: install-ci-tools.sh DESTINATION}
mkdir -p "$destination"
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

curl --fail --location --retry 3 --silent --show-error \
  https://github.com/koalaman/shellcheck/releases/download/v0.11.0/shellcheck-v0.11.0.linux.x86_64.tar.gz \
  -o "$temporary/shellcheck.tar.gz"
printf '%s  %s\n' b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6 "$temporary/shellcheck.tar.gz" | sha256sum --check
tar --no-same-owner -xzf "$temporary/shellcheck.tar.gz" -C "$destination" --strip-components=1 shellcheck-v0.11.0/shellcheck

curl --fail --location --retry 3 --silent --show-error \
  https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz \
  -o "$temporary/actionlint.tar.gz"
printf '%s  %s\n' 8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8 "$temporary/actionlint.tar.gz" | sha256sum --check
tar --no-same-owner -xzf "$temporary/actionlint.tar.gz" -C "$destination" actionlint
