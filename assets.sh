#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

PIT_ASSETS=(
    https://artifactory.algol60.net/artifactory/csm-images/unstable/cray-pre-install-toolkit/1.4.15/cray-pre-install-toolkit-sle15sp2.x86_64-1.4.15-20210918190528-g735efde.iso
    https://artifactory.algol60.net/artifactory/csm-images/unstable/cray-pre-install-toolkit/1.4.15/cray-pre-install-toolkit-sle15sp2.x86_64-1.4.15-20210918190528-g735efde.packages
    https://artifactory.algol60.net/artifactory/csm-images/unstable/cray-pre-install-toolkit/1.4.15/cray-pre-install-toolkit-sle15sp2.x86_64-1.4.15-20210918190528-g735efde.verified
)

KUBERNETES_ASSETS=(
    https://arti.dev.cray.com/artifactory/node-images-stable-local/shasta/kubernetes/0.1.80/kubernetes-0.1.80.squashfs
    https://arti.dev.cray.com/artifactory/node-images-stable-local/shasta/kubernetes/0.1.80/5.3.18-24.75-default-0.1.80.kernel
    https://arti.dev.cray.com/artifactory/node-images-stable-local/shasta/kubernetes/0.1.80/initrd.img-0.1.80.xz
)

STORAGE_CEPH_ASSETS=(
    https://arti.dev.cray.com/artifactory/node-images-stable-local/shasta/storage-ceph/0.1.78/storage-ceph-0.1.78.squashfs
    https://arti.dev.cray.com/artifactory/node-images-stable-local/shasta/storage-ceph/0.1.78/5.3.18-24.75-default-0.1.78.kernel
    https://arti.dev.cray.com/artifactory/node-images-stable-local/shasta/storage-ceph/0.1.78/initrd.img-0.1.78.xz
)

HPE_SIGNING_KEY=https://arti.dev.cray.com/artifactory/dst-misc-stable-local/SigningKeys/HPE-SHASTA-RPM-PROD.asc

set -exo pipefail

# usage: cmd_retry <cmd> <arg1> ...
#
# Run the specified command until it passes or until it fails too many times
function cmd_retry
{
    local -i attempt
    # For now I'm hard coding these values, but it would be easy to make them into function
    # arguments in the future, if desired
    local -i max_attempts=10
    local -i sleep_time=12
    attempt=1
    while [ true ]; do
        # We redirect to stderr just in case the output of this command is being piped
        echo "Attempt #$attempt to run: $*" 1>&2
        if "$@" ; then
            return 0
        elif [ $attempt -lt $max_attempts ]; then
           echo "Sleeping ${sleep_time} seconds before retry" 1>&2
           sleep ${sleep_time}
           attempt=$(($attempt + 1))
           continue
        fi
        echo "ERROR: Unable to get $url even after retries" 1>&2
        return 1
    done
    echo "PROGRAMMING LOGIC ERROR: This line should never be reached" 1>&2
    exit 1
}

# Verify assets exist
for url in "${PIT_ASSETS[@]}"; do cmd_retry curl -sfSLI "$url"; done
for url in "${KUBERNETES_ASSETS[@]}"; do cmd_retry curl -sfSLI "$url"; done
for url in "${STORAGE_CEPH_ASSETS[@]}"; do cmd_retry curl -sfSLI "$url"; done
cmd_retry curl -sfSLI "$HPE_SIGNING_KEY"
