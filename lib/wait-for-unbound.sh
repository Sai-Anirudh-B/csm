#!/usr/bin/env bash

set -exo pipefail

# Wait for unbound to be available
kubectl wait -n services deployment cray-dns-unbound --for=condition=available --timeout=5m

# Wait for coredns job to complete
kubectl wait -n services job cray-dns-unbound-coredns --for=condition=complete --timeout=5m

# Wait for at least cone cray-dns-unbound-manager job to complete
function poll-saw-completed-job() {
    while [[ $(kubectl get event -n services --field-selector "involvedObject.kind=CronJob,involvedObject.name=cray-dns-unbound-manager,reason=SawCompletedJob" -o json | jq '.items | length') -eq 0 ]]; do
        echo >&2 "waiting for cronjob.batch/cray-dns-unbound-manager to run a job"
        sleep 10s
    done
}
export -f poll-saw-completed-job
timeout 5m bash -c 'set -exo pipefail; poll-saw-completed-job'
kubectl wait -n services job -l cronjob-name=cray-dns-unbound-manager --for=condition=complete --timeout=5m

# A little extra buffer
sleep 10

# Reads "IP HOSTNAME[ ...]" lines from stdin and verifies that Unbound resolves
# each HOSTNAME to the expected IP.
function verify() {
    local unbound_nmn_ip="$(kubectl get -n services service cray-dns-unbound-udp-nmn -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
    local failures=0

    while read ipaddr hostnames; do
        read -a names <<< "$hostnames"
        for h in "${names[@]}"; do
            if [[ "$ipaddr" == "$(dig "@${unbound_nmn_ip}" +short "$h")" ]]; then
                echo >&2 "ok: unbound resolves: ${h} -> ${ipaddr}"
            else 
                echo >&2 "error: Unbound resolution failure: ${h} does not resolve to ${ipaddr}"
                ((failures++))
            fi
        done
    done
    return $failures
}

ingress_ip="$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

verify <<EOF
${ingress_ip} packages.local registry.local
EOF
