#!/usr/bin/env bash

# docker run --rm --entrypoint /bin/bash quay.io/influxdb/cross-builder:go1.20.5-b76a62e4c08e4a01ccfc02d6e7b7b4720ebed2ef -c 'cat "$(which build-version.sh)"'

set -eo pipefail

function main () {
    if [[ $# != 1 ]]; then
        >&2 echo Usage: $0 '<build-type>'
        >&2 echo "Valid build types are 'release', 'nightly', and 'snapshot'"
        exit 1
    fi
    local -r build_type=$1

    local version
    case "$build_type" in
        release)
            if [ -n "$CIRCLE_TAG" ]; then
                version="$CIRCLE_TAG"
            else
                version=$(git describe --tags --abbrev=0 --exact-match)
            fi
            ;;
        nightly)
            version=$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)+nightly.$(date +%Y.%m.%d)
            ;;
        snapshot)
            version=$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)+SNAPSHOT.$(git rev-parse --short HEAD)
            ;;
        *)
            >&2 echo "Error: unknown build type '$build_type'"
            >&2 echo "Valid build types are 'release', 'nightly', and 'snapshot'"
            ;;
    esac
    if [ -z "$version" ]; then
        >&2 echo "Error: couldn't compute version for build type '$build_type'"
        exit 1
    fi

    echo "$version"
}

main ${@}