#!/usr/bin/env bash

# this file was obtained from the `quay.io/influxdb/cross-builder` docker image via:
# $ docker run --rm --entrypoint /bin/bash quay.io/influxdb/cross-builder:go1.20.5-b76a62e4c08e4a01ccfc02d6e7b7b4720ebed2ef -c 'cat /install-go.sh'
# after that, I manually edited it to point to arm64 instead of amd64 -- and to ignore hash

# Values are from https://golang.org/dl/
# They are the `go<version>-linux-amd64.tar.gz` shas
function go_expected_sha () {
    case "$GO_VERSION" in
        1.20.5)
            echo d7ec48cde0d3d2be2c69203bc3e0a44de8660b9c09a6e85c4732a3f7dc442612
            ;;
        1.19.10)
            echo 8b045a483d3895c6edba2e90a9189262876190dbbd21756870cdd63821810677
            ;;
        1.18.9)
            echo 015692d2a48e3496f1da3328cf33337c727c595011883f6fc74f9b5a9c86ffa8
            ;;
        1.17.13)
            echo 4cdd2bc664724dc7db94ad51b503512c5ae7220951cac568120f64f8e94399fc
            ;;
        *)
            >&2 echo Error: Unexpected Go version "$GO_VERSION"
            exit 1
            ;;
    esac
}

function main () {
    if [[ -z "$GO_VERSION" ]]; then
        >&2 echo Error: GO_VERSION must be set in env
        exit 1
    fi

    local -r go_archive=go$GO_VERSION.linux-arm64.tar.gz
    local -r go_url=https://golang.org/dl/${go_archive}

    curl -sS -L "$go_url" -O
    sha256sum "$go_archive"
    #echo "$(go_expected_sha)  ${go_archive}" | sha256sum --check --
    tar xzf "$go_archive" -C /
    rm "$go_archive"
}

main
