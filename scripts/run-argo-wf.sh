#!/usr/bin/env bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

source ${BASEDIR}/start-k3s.sh

wf_name="$(argo submit ${1} -o json | jq -r .metadata.name | tee ${BASEDIR}/wf-id)"

if [[ -z "${NO_WAIT_BEFORE_WATCH}" ]]; then
  ${BASEDIR}/wait_for.sh ${wf_name}
fi

argo watch ${wf_name}

wf="$(cat ${BASEDIR}/wf-id)"
if [[ ! "$(kubectl get Workflow ${wf} -o json | jq -r .status.phase)" == "Succeeded" ]]; then
  echo "${wf} failed!"
  exit 1
fi
