#!/bin/bash

# this file was obtained from the `quay.io/influxdb/cross-builder` docker image via:
# $ docker run --rm --entrypoint /bin/bash quay.io/influxdb/cross-builder:go1.20.5-b76a62e4c08e4a01ccfc02d6e7b7b4720ebed2ef -c 'cat /install-rust.sh'


set -ex

# flux is on this version: https://github.com/influxdata/flux/blob/ac7d2b9c028485368447a42b9965b3e14e30c7aa/.circleci/config.yml#L90
RUST_LATEST_VERSION=1.63.0
# For security, we specify a particular rustup version and a SHA256 hash, computed
# ourselves and hardcoded here. When updating `RUSTUP_LATEST_VERSION`:
#   1. Download the new rustup script from https://github.com/rust-lang/rustup/releases.
#   2. Audit the script and changes to it. You might want to grep for strange URLs...
#   3. Update `OUR_RUSTUP_SHA` with the result of running `sha256sum rustup-init.sh`.
RUSTUP_LATEST_VERSION=1.25.1
OUR_RUSTUP_SHA="173f4881e2de99ba9ad1acb59e65be01b2a44979d83b6ec648d0d22f8654cbce"


# Download rustup script
curl --proto '=https' --tlsv1.2 -sSf \
  https://raw.githubusercontent.com/rust-lang/rustup/${RUSTUP_LATEST_VERSION}/rustup-init.sh -O

# Verify checksum of rustup script. Exit with error if check fails.
echo "${OUR_RUSTUP_SHA} rustup-init.sh" | sha256sum --check -- \
    || { echo "Checksum problem!"; exit 1; }

# Run rustup.
sh rustup-init.sh --default-toolchain "$RUST_LATEST_VERSION" -y

# Ensure cargo is runnable
source $HOME/.cargo/env
cargo help
