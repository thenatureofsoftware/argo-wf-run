#!/usr/bin/env bash

#example=https://raw.githubusercontent.com/argoproj/argo/master/examples/artifact-passing.yaml
example=https://raw.githubusercontent.com/argoproj/argo/master/examples/dag-diamond-steps.yaml
example_file="$(basename $example)"

echo "# You need Docker installed"
echo -e "# Install argo-wf-run\n"
sleep 1
cmd="curl -s -O https://raw.githubusercontent.com/TheNatureOfSoftware/argo-wf-run/master/argo-wf-run && chmod +x argo-wf-run"
echo $cmd
eval $cmd
sleep 5

echo -e "\n# If your workflow produces output, create an output directory \n"
sleep 1
cmd="mkdir -p ./artifacts"
echo $cmd
eval $cmd
sleep 2

echo -e "\n# Run workflow\n"
curl -s -O $example
sleep 1
#cmd="./argo-wf-run -d ./artifacts -f $example_file"
cmd="./argo-wf-run -f $example_file"
echo $cmd
sleep 7
clear
eval $cmd