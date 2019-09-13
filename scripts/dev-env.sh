#!/usr/bin/env bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

docker build --no-cache -t thenatureofsoftware/argo-wf-runner:latest ${BASEDIR}/..

NETWORK=k3d

docker rm -f docker
docker network rm ${NETWORK} 
docker network create ${NETWORK}
docker run -d --privileged --name docker --network ${NETWORK}  docker:19.03.2-dind dockerd --host=tcp://0.0.0.0:2375
docker run --rm -it --entrypoint=sh \
-e DOCKER_HOST=tcp://docker:2375/ \
-v ${PWD}:/workspace \
--network ${NETWORK} thenatureofsoftware/argo-wf-runner:latest
