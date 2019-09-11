#!/usr/bin/env bash
set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

function log () {
  level=${1}
  shift
  if [[ -z "$DEBUG" ]] && [[ ! "${level}" == "DEBUG" ]] || [[ ! -z "$DEBUG" ]]; then
    echo "$(date '+%Y-%m-%HT%T%Z') ${level} $@"
  fi
}

function info () {
  log INFO $@
}

function error () {
  log ERROR $@
}

function debug () {
  log DEBUG $@
}

function check_tool () {
  if [[ "$(which ${1} 2> /dev/null)" == "" ]]; then
    echo "${1} not found in PATH"
    exit 1
  fi
}

function check_tools () {
  for i in $@; do
    check_tool ${i}
  done
}

check_tools argo helm k3d
export KUBECONFIG=false

k3d delete --name gibil || true
k3d create --name gibil --publish 8080:80
sleep 5
export KUBECONFIG="$(k3d get-kubeconfig --name='gibil')"
kubectl create ns argo
kubectl -n argo apply -f ${BASEDIR}/install.yaml
kubectl create clusterrolebinding default-argo-cluster-role --serviceaccount default:default --clusterrole argo-cluster-role
