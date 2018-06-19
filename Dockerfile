FROM ubuntu:trusty

ENV GRAAL_VERSION 1.0.0-rc2

RUN apt-get update && \
  apt-get install -y \
  build-essential \
  zlib1g-dev \
  curl \
  gcc \
  && rm -rf /var/lib/apt/lists/* && \
  cd /opt && \
  curl -L https://github.com/oracle/graal/releases/download/vm-${GRAAL_VERSION}/graalvm-ce-${GRAAL_VERSION}-linux-amd64.tar.gz | \
  tar -xz

ENV PATH $PATH:/opt/graalvm-ce-${GRAAL_VERSION}/bin

CMD ["native-image"]