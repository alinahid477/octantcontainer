FROM debian:buster-slim

RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	openssh-client \
	psmisc \
	nano \
	net-tools \
	&& curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
	&& chmod +x /usr/local/bin/kubectl

ENV VERSION 0.20.0

RUN mkdir /octant && cd /octant && curl -o octant.deb -L https://github.com/vmware-tanzu/octant/releases/download/v${VERSION}/octant_${VERSION}_Linux-64bit.deb && dpkg -i octant.deb && rm -rf /octant

ENV OCTANT_LISTENER_ADDR=0.0.0.0:51234
ENV OCTANT_DISABLE_OPEN_BROWSER=true

COPY binaries/init.sh /usr/local/
RUN chmod +x /usr/local/init.sh

# comment the below 2 line if you do not have tmc
COPY binaries/tmc /usr/local/bin/
RUN chmod +x /usr/local/bin/tmc

# comment the below 2 line if you do not have kubectl and kubectl-vsphere
COPY binaries/kubectl-vsphere /usr/local/bin/
RUN chmod +x /usr/local/bin/kubectl-vsphere

# VOLUME ["/root/.kube"]

ENTRYPOINT ["/usr/local/init.sh"]