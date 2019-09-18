#!/usr/bin/env bash

set -e

declare -a args
for i in "$@"; do
  args+=($(printf "%q" "$i"))
done

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
VERSION=rc

docker build -t thenatureofsoftware/argo-wf-run:${VERSION} ${BASEDIR}/..
export VERSION=${VERSION}
bash -c "VERSION=${VERSION} ${BASEDIR}/../argo-wf-run $(echo ${args[@]})"