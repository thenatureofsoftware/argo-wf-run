# Argo Workflow Runner

Let's you run any [Argo Workflow](https://github.com/argoproj/argo) from the command line using [`k3d`](https://github.com/rancher/k3d) and [`k3s`](https://github.com/rancher/k3s).

## How it works

The `argo-wf-run` script starts a Docker `dind` container with `k3d` and starts
a single node `k3s` cluster and deploys `argo-workflow`. The script runs the
workflow using the Docker `exec` command.

When running in a GitLab CI/CD pipeline the Docker `dind` container is started as a `service` and the GitLab Runner starts the `argo-wf-run` container that connects to the Docker daemon on `tcp://docker:2375`.

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

services:
  - docker:19.03.2-dind

build1:
  tags:
    - docker
  script:
    - ./scripts/run-argo-wf.sh https://raw.githubusercontent.com/argoproj/argo/master/examples/dag-diamond-steps.yaml
```
`.gitlab-ci.yaml`
