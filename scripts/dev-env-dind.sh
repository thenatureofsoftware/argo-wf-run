#!/usr/bin/env bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
VERSION=rc

docker build -t thenatureofsoftware/argo-wf-runner:${VERSION} ${BASEDIR}/..
docker push thenatureofsoftware/argo-wf-runner:${VERSION}

NETWORK=k3d

docker rm -f docker || true
docker network rm ${NETWORK} || true
docker network create ${NETWORK}
docker run -d --privileged --name docker --network ${NETWORK}  docker:19.03.2-dind dockerd --host=tcp://0.0.0.0:2375
docker run --rm -it \
--entrypoint=bash \
-e DOCKER_HOST=tcp://docker:2375/ \
-e VERSION=${VERSION} \
-e AWR_WF_SERVICE=docker \
-e AWR_WF_START_SHELL=true \
-v ${PWD}:/workspace \
--network ${NETWORK} thenatureofsoftware/argo-wf-runner:${VERSION}
