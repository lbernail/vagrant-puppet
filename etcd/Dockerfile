FROM ubuntu:12.04
RUN apt-get update -q
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy build-essential curl git
RUN mkdir /opt/etcd
RUN curl -s -S -L https://github.com/coreos/etcd/releases/download/v0.4.1/etcd-v0.4.1-linux-amd64.tar.gz | tar -xzC /opt/etcd --strip-components 1
EXPOSE 4001 7001
ENTRYPOINT ["/opt/etcd/etcd"]
