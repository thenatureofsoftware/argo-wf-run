#!/usr/bin/env bash

set -e

export AWR_WF_PARAMETERS=message%3A%20Hello%20World%20from%20argo-wf-run%5Cn
./scripts/run-argo-wf.sh https://raw.githubusercontent.com/argoproj/argo/master/examples/global-parameters.yaml --wait
export KUBECONFIG=$(k3d get-kubeconfig -n argo-wf)

[[ "$(argo get $(cat wf-id) -o json | jq -r '.status.phase')" == "Succeeded" ]] \
&& [[ "$(argo get $(cat wf-id) -o json | jq -r '.spec.arguments.parameters[0].value')" == "Hello World from argo-wf-run" ]]