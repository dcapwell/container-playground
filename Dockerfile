FROM centos:centos7

# Setup golang
RUN \
  cd /usr/local && \
  curl -L 'https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz' | tar -xzf - && \
  echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/bashrc && \
  echo "export GOBIN=/root/projects/bin" >> /etc/bashrc && \
  echo "export GOPATH=/root/projects/src" >> /etc/bashrc

ENV PATH    $PATH:/usr/local/go/bin
ENV GOBIN   /root/projects/bin
ENV GOPATH  /root/projects/src

# install dependencies
RUN \
  yum groupinstall -y "development tools" && \
  yum install -y tree git make gpgme-devel libassuan-devel device-mapper-devel btrfs-progs-devel libseccomp-devel which sudo

# install skopeo
# https://github.com/projectatomic/skopeo
# Sine 1.0 spec is not out yet, oci tools and spokeo are not in-sync (https://github.com/projectatomic/skopeo/issues/299)
# commit that broke the integration
# https://github.com/projectatomic/skopeo/pull/293
RUN \
  git clone https://github.com/projectatomic/skopeo $GOPATH/src/github.com/projectatomic/skopeo && \
  cd $GOPATH/src/github.com/projectatomic/skopeo && \
  git checkout 0e1ba1fb70396e589408ce70de8ba98f4f191d56 && \
  make binary-local && \
  mv skopeo /usr/local/bin/ && \
  mkdir -p /etc/containers && \
  cp default-policy.json /etc/containers/policy.json

# install OCI image tools
# https://github.com/opencontainers/image-tools/
RUN \
  git clone https://github.com/opencontainers/image-tools.git $GOPATH/src/github.com/opencontainers/image-tools && \
  cd $GOPATH/src/github.com/opencontainers/image-tools && \
  make tools && \
  mv oci-* /usr/local/bin/

# install OCI runtime tools
# https://github.com/opencontainers/runtime-tools
RUN \
  git clone https://github.com/opencontainers/runtime-tools.git $GOPATH/src/github.com/opencontainers/runtime-tools && \
  cd $GOPATH/src/github.com/opencontainers/runtime-tools && \
  make && \
  mv oci-runtime-tool /usr/local/bin/

# install runC
# https://github.com/opencontainers/runc
RUN \
  git clone https://github.com/opencontainers/runc.git $GOPATH/src/github.com/opencontainers/runc && \
  cd $GOPATH/src/github.com/opencontainers/runc && \
  git fetch origin pull/774/head:rootless-containers && \
  git checkout rootless-containers && \
  make BUILDTAGS="seccomp selinux ambient" && \
  mv runc /usr/local/bin/

# install umoci
# https://github.com/cyphar/umoci
RUN \
  git clone https://github.com/cyphar/umoci.git $GOPATH/src/github.com/cyphar/umoci && \
  cd $GOPATH/src/github.com/cyphar/umoci && \
  make && \
  mv umoci /usr/local/bin/
