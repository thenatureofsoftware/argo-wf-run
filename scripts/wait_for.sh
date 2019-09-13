#!/usr/bin/env bash
wf=${1}
function wf_status () {
    echo -n "$(kubectl get Workflow ${wf} -o json | jq -r .status.phase)"
}
echo -n "Running workflow ${wf} "
until $([[ $(wf_status) == 'Succeeded' ]] || [[ $(wf_status) == 'Failed' ]]); do printf '.'; sleep 2; done
echo " Done"


