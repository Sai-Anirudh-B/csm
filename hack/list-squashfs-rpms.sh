#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

SQUASHFS_TOOLS_IMAGE="arti.hpc.amslabs.hpecorp.net/internal-docker-stable-local/squashfs-tools:0.1.0"

function rpm-list() {
    while [[ $# -gt 0 ]]; do
        docker run --rm --privileged -v "$(realpath "$(dirname "$1")"):/data" "$SQUASHFS_TOOLS_IMAGE" /usr/local/bin/list-rpms.sh "/data/$(basename "$1")"
        shift
    done
}

set -ex
set -o pipefail

rpm-list "$@" | sort -u
