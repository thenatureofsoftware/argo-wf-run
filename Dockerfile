FROM docker:19.03.2-dind as csi

WORKDIR /
RUN apk --no-cache add git \
&& git clone https://github.com/kubernetes-csi/csi-driver-host-path.git >/dev/null 2>&1 \
&& cd csi-driver-host-path \
&& git checkout v1.2.0-rc8 \
&& cd /csi-driver-host-path/deploy/kubernetes-1.15/hostpath \
&& sed -i 's;/var/lib/kubelet;/var/lib/rancher/k3s/agent/kubelet;g' *

FROM docker:19.03.2-dind

ENV AWR_WF_SERVICE=localhost

RUN apk --no-cache add bash curl jq \
&& mkdir /argo-wf \
&& curl -sSL -o /usr/local/bin/argo https://github.com/argoproj/argo/releases/download/v2.3.0/argo-linux-amd64 \
&& chmod +x /usr/local/bin/argo \
&& curl -sSL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl \
&& chmod +x /usr/local/bin/kubectl \
&& curl -sSL -o /usr/local/bin/k3d https://github.com/rancher/k3d/releases/download/v1.3.1/k3d-linux-amd64 \
&& chmod +x /usr/local/bin/k3d \
&& curl -sSL -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc \
&& chmod +x /usr/local/bin/mc

WORKDIR /argo-wf

COPY --from=csi /csi-driver-host-path/deploy /csi-driver-host-path/deploy/
COPY scripts /argo-wf/scripts
COPY manifests /argo-wf/manifests
