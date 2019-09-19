#!/usr/bin/env bash

if [[ ! -f ./argo-wf-run ]]; then
  echo -e "This script is meant to be run from the project root directory!"
  exit 1
fi

for i in $(ls tests/test*.sh); do
  testName=$(basename $i)
  result="Succeeded"
  ./$i >/dev/null 2>&1
  if [[ ! $? -eq 0 ]]; then
    result="Failed"
  fi
  echo -e "$testName\t $result"
done