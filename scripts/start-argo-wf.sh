#!/usr/bin/env bash
set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

CLUSTER_NAME=${CLUSTER_NAME:-argo-wf}
echo "Setting up k3s cluster ${CLUSTER_NAME}"

k3d delete -n ${CLUSTER_NAME} || true
k3d create -n ${CLUSTER_NAME} --image rancher/k3s:v0.9.0-rc2 --server-arg=--no-deploy=traefik --server-arg=--no-deploy=servicelb

echo -n "Waiting k3s to start "
until $(k3d get-kubeconfig --name=${CLUSTER_NAME} &> /dev/null); do printf "."; sleep 5; done
echo " OK"

export KUBECONFIG="$(k3d get-kubeconfig --name=${CLUSTER_NAME})"
sed -i -e 's/localhost/docker/g' ${KUBECONFIG}
sed -i -e 's/127.0.0.1/docker/g' ${KUBECONFIG}

kubectl create ns argo || true
kubectl -n argo apply -f ${BASEDIR}/../argo-workflow-manifest.yaml || true
kubectl create clusterrolebinding default-argo-cluster-role --serviceaccount default:default --clusterrole argo-cluster-role || true

echo -n "Waiting for argo-workflow to start "
until $([[ $(kubectl -n argo get pod -o json -l app=workflow-controller | jq -r '.items[0].status.phase') == 'Running' ]]); do printf "."; sleep 2; done
echo " OK"
