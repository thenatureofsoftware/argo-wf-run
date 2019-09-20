# Argo Workflow Runner

Let's you run any [Argo Workflow](https://github.com/argoproj/argo) from the command line using [`k3d`](https://github.com/rancher/k3d) and [`k3s`](https://github.com/rancher/k3s).

```
argo-wf-run runs an Argo workflow from the command line

Usage:
  argo-wf-run                        starts a shell for running workflows with argo cli
  argo-wf-run (-f|--filename) FILE   runs argo submit with a single workflow

Flags:
  -f|--filename                      Argo workflow file to run
  -v|--volume                        Bind mount a volume
  -d|--directory                     Write workflow output to directory
  -s|--service                       The hostname where to find k3s
  -p|--parameter                     Pass an input parameter
  --parameter-file                   Pass a file containing all input parameters
  -w|--wait                          Wait for the workflow to complete
  -S|--storage                       Setup a storage provider

Example:
  $ export ARGO_EXAMPLES=https://raw.githubusercontent.com/argoproj/argo/master/examples
  $ # Simple workflow
  $ argo-wf-run -f $ARGO_EXAMPLES/dag-diamond-steps.yaml
  $ # Supports parameters
  $ argo-wf-run p message='Hello' -f $ARGO_EXAMPLES/global-parameters.yaml
  $ # If your using volumes or pvc
  $ argo-wf-run -S -f $ARGO_EXAMPLES/volumes-pvc.yaml
```

## How to install

You need to have Docker installed.

```
$ curl -s -o /usr/local/bin/argo-wf-run \
https://raw.githubusercontent.com/TheNatureOfSoftware/argo-wf-run/master/argo-wf-run \
&& chmod +x /usr/local/bin/argo-wf-run
$ argo-wf-run --help
```

## Use Cases

### Run any workflow from the command line

You can use `argo-wf-run` to execute a single workflow, without a Kubernetes cluster with Argo deployed:

Run the `dag-diamond-steps` example from [Argo Workflows](https://github.com/argoproj/argo):
```
$ ./argo-wf-run https://raw.githubusercontent.com/argoproj/argo/master/examples/dag-diamond-steps.yaml
```
Or you can run a local workflow file:
```
$ curl -sSLO https://raw.githubusercontent.com/argoproj/argo/master/examples/dag-diamond-steps.yaml
$ ./argo-wf-run dag-diamond-steps.yaml
```

### Start an Argo Workflow environment that includes the argo cli

If you don't specify a workflow file to run `argo-wf-run` will start an environment with the `argo` cli and `argo-workflow` up and running:

```
$ ./argo-wf-run
Setting up k3s cluster argo-wf
Waiting for k3s to start . OK
Waiting for argo-workflow to start ............ OK
argo /work> k3d list
+---------+----------------------------------+---------+---------+
|  NAME   |              IMAGE               | STATUS  | WORKERS |
+---------+----------------------------------+---------+---------+
| argo-wf | docker.io/rancher/k3s:v0.9.0-rc2 | running |   0/0   |
+---------+----------------------------------+---------+---------+
argo /work> kubectl cluster-info
Kubernetes master is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
argo /work> argo list
NAME   STATUS   AGE   DURATION   PRIORITY
argo /work> 
```

The current directory is mounted as `/work`.

### Run Argo Workflow as part of your CI/CD pipeline

You can run Argo Workflow as a satellite managing your environments from your workflow.
For example you can create a workflow for spinning up an test environment with Terraform, or whatever.

Here's a GitLab CI/CD pipeline example:

```yaml
image: thenatureofsoftware/argo-wf-run:latest

variables:
  DOCKER_HOST: tcp://docker:2375
  # It's the docker daemon that exposes the k3d
  # cluster and we need to set the hostname for kubeconfig.
  AWR_WF_SERVICE: docker

services:
  - docker:19.03.2-dind

build1:
  tags:
    - docker
  script:
    - ./scripts/run-argo-wf.sh https://raw.githubusercontent.com/argoproj/argo/master/examples/dag-diamond-steps.yaml
```
`.gitlab-ci.yaml`

## Workflow artifacts

When a workflow produces output/artifact you need to add the `--directory|-d` flag to create
a default artifact repository. When the `-d` flag is set `argo-wf-run` will configure a
Default [Minio](https://min.io/) Artifact Repository and copy the artifacts to the specified
directory when the workflow is finished.

When running in a pipeline and invoking the `./scripts/run-argo-wf.sh` with a workflow
that produces artifacts you need to make sure the `/argo-wf_artifacts` directory exists.

## Default Storage Class

The `-S|--storage` flag enables a default `storageclass` for the `k3s` cluster that can be
utilized with `volumeClaimTemplates` or create your own, take a look at the
[Argo Documentation](https://github.com/argoproj/argo/blob/master/examples/README.md#volumes).

## How it works

The `argo-wf-run` script starts a Docker `dind` container with `k3d` and starts
a single node `k3s` cluster and deploys `argo-workflow`. The script runs the
workflow using the Docker `exec` command.

When running in a GitLab CI/CD pipeline the Docker `dind` container is started as a `service` and the GitLab Runner starts the `argo-wf-run` container that connects to the Docker daemon on `tcp://docker:2375`.

