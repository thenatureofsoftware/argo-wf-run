#!/usr/bin/env bash

./scripts/run-argo-wf.sh https://raw.githubusercontent.com/argoproj/argo/master/examples/dag-diamond-steps.yaml --wait
export KUBECONFIG=$(k3d get-kubeconfig -n argo-wf)
[[ "$(argo get $(cat wf-id) -o json | jq -r '.status.phase')" == "Succeeded" ]]
