#!/usr/bin/env bash

export AWR_WF_STORAGE=true
./scripts/run-argo-wf.sh https://raw.githubusercontent.com/argoproj/argo/master/examples/volumes-pvc.yaml --wait
export KUBECONFIG=$(k3d get-kubeconfig -n argo-wf)
[[ "$(argo get $(cat wf-id) -o json | jq -r '.status.phase')" == "Succeeded" ]]
