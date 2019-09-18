#!/usr/bin/env bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

function urldecode() {
  # urldecode <string>
  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}"
}

function parameters() {
  if [[ -z "${AWR_WF_PARAMETERS}" ]]; then
    echo -n ""
  else
    echo -e "$(urldecode "${AWR_WF_PARAMETERS}")" > /argo-wf-run-parameters.yaml
    echo -n "--parameter-file /argo-wf-run-parameters.yaml "
  fi
}

source ${BASEDIR}/start-k3s.sh

wf_file="${1}"
shift

argo submit ${wf_file} $@ $(parameters)-o json | jq -r .metadata.name | tee wf-id
wf="$(cat wf-id)"
argo watch "${wf}"

if [[ ! "$(kubectl get Workflow ${wf} -o json | jq -r .status.phase)" == "Succeeded" ]]; then
  echo "${wf} failed!"
  exit 1
fi
