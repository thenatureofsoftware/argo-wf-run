#!/usr/bin/env bash
set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
MANIFESTSDIR="$( cd "${BASEDIR}/../manifests" >/dev/null 2>&1 && pwd )"
CLUSTER_NAME=${CLUSTER_NAME:-argo-wf}

function artifactsEnabled() {
  [[ -d /argo-wf-artifacts ]]
}

function copyArtifacts() {
  if artifactsEnabled; then
    echo "Moving artifacts to artifact directory"
    mc cp -r minio/argo /argo-wf-artifacts/
  fi
}

function k3s_is_running() {
  $( k3d get-kubeconfig --name=${CLUSTER_NAME} >/dev/null 2>&1 ) && [[ -n "$(k3d list | grep -e 'argo-wf' | grep -e 'running')" ]]
}

function start_k3s() {
  echo "Setting up k3s cluster ${CLUSTER_NAME}"

  k3d delete -n ${CLUSTER_NAME} >/dev/null 2>&1 || true
  if artifactsEnabled; then
    k3d create -n ${CLUSTER_NAME} \
    --image rancher/k3s:v0.9.0-rc2 \
    --workers 1 \
    --publish 9000:31000@k3d-${CLUSTER_NAME}-worker-0 \
    --server-arg=--no-deploy=traefik >/dev/null 2>&1
  else
    k3d create -n ${CLUSTER_NAME} \
    --image rancher/k3s:v0.9.0-rc2 \
    --workers 1 \
    --server-arg=--no-deploy=traefik \
    --server-arg=--no-deploy=servicelb >/dev/null 2>&1
  fi
}

function argo_is_running() {
  [[ $(kubectl -n argo get pod -o json -l app=workflow-controller | jq -r '.items[0].status.phase') == 'Running' ]]
}

function start_argo() {
  kubectl create ns argo &> /dev/null || true
  kubectl -n argo apply -f ${MANIFESTSDIR}/argo-workflow-manifest.yaml &> /dev/null
  kubectl create clusterrolebinding default-argo-cluster-role --serviceaccount default:default --clusterrole argo-cluster-role &> /dev/null
}

function minio_is_running() {
  [[ $(kubectl -n default get pod -o json -l app=minio | jq -r '.items[0].status.phase') == 'Running' ]] && \
  $( mc config host add minio http://${AWR_WF_SERVICE}:9000 \
    $(kubectl get secret minio -o json | jq -r '.data.accesskey' | base64 -d) \
    $(kubectl get secret minio -o json | jq -r '.data.secretkey' | base64 -d) >/dev/null 2>&1 )
} 

# Start k3s
if ! k3s_is_running; then
  start_k3s
  echo -n "Waiting for k3s to start "
  until k3s_is_running; do printf "."; sleep 5; done
  echo " OK"
fi

# Setup kubeconfig
export KUBECONFIG="$(k3d get-kubeconfig --name=${CLUSTER_NAME})"
if [[ ! "${AWR_WF_SERVICE}" == "localhost" ]]; then
  sed -i -e "s/localhost/${AWR_WF_SERVICE}/g" ${KUBECONFIG}
  sed -i -e "s/127.0.0.1/${AWR_WF_SERVICE}/g" ${KUBECONFIG}
fi

# Start argo workflow
if ! argo_is_running; then
  start_argo
  echo -n "Waiting for argo-workflow to start "
  until argo_is_running; do printf "."; sleep 2; done
  echo " OK"
fi

if artifactsEnabled; then
  if ! minio_is_running; then
    kubectl apply -f ${MANIFESTSDIR}/minio.yaml &> /dev/null
  
    echo -n "Waiting for minio to start "
    until minio_is_running; do printf "."; sleep 2; done
    echo " OK"

    mc mb minio/argo
  fi
fi

trap "copyArtifacts" EXIT

if [[ ! -z "${START_SHELL}" ]]; then
  export PS1="argo \w> "
  set +e
fi
