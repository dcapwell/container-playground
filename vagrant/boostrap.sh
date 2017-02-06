#!/usr/bin/env bash

#set -x
set -e
set -o pipefail
set -u

bin=$(cd $(dirname "$0") > /dev/null; pwd)

export PATH=$PATH:/usr/local/go/bin
export PROJECT_DIR=/src/projects
export GOBIN=${PROJECT_DIR}/bin
export GOPATH=${PROJECT_DIR}/src

setup_kernel() {
  sudo grubby --args="user_namespace.enable=1" --update-kernel $(ls /boot/$(cat /proc/cmdline | cut -d/ -f2 | cut -d' ' -f1))
}

install_packages() {
 sudo yum group install -y "Development Tools" 
 sudo yum install -y \
   tree \
   git \
   make \
   which \
   gpgme-devel \
   libassuan-devel \
   libseccomp-devel \
   device-mapper-devel \
   btrfs-progs-devel
}

install_go() {
  cd /usr/local
    curl -L 'https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz' | sudo tar -xzf -
  cd -
  echo "export PATH=\$PATH:/usr/local/go/bin" >> $HOME/.bashrc
  echo "export GOBIN=${PROJECT_DIR}/bin"      >> $HOME/.bashrc
  echo "export GOPATH=${PROJECT_DIR}/src"     >> $HOME/.bashrc
  sudo mkdir -p "$GOBIN" "$GOPATH"
  sudo chmod a+rwx "$GOBIN" "$GOPATH"
}

install_go_projects() {
  # install skopeo
  # https://github.com/projectatomic/skopeo
  # Sine 1.0 spec is not out yet, oci tools and spokeo are not in-sync (https://github.com/projectatomic/skopeo/issues/299)
  # commit that broke the integration
  # https://github.com/projectatomic/skopeo/pull/293
  git clone https://github.com/projectatomic/skopeo $GOPATH/src/github.com/projectatomic/skopeo
  cd $GOPATH/src/github.com/projectatomic/skopeo
  git checkout 0e1ba1fb70396e589408ce70de8ba98f4f191d56
  make binary-local
  sudo mv skopeo /usr/local/bin/
  sudo mkdir -p /etc/containers
  sudo cp default-policy.json /etc/containers/policy.json

  # install OCI image tools
  # https://github.com/opencontainers/image-tools/
  git clone https://github.com/opencontainers/image-tools.git $GOPATH/src/github.com/opencontainers/image-tools
  cd $GOPATH/src/github.com/opencontainers/image-tools
  make tools
  sudo mv oci-* /usr/local/bin/

  # install OCI runtime tools
  # https://github.com/opencontainers/runtime-tools
  git clone https://github.com/opencontainers/runtime-tools.git $GOPATH/src/github.com/opencontainers/runtime-tools
  cd $GOPATH/src/github.com/opencontainers/runtime-tools
  make
  sudo mv oci-runtime-tool /usr/local/bin/

  # install runC
  # https://github.com/opencontainers/runc
  git clone https://github.com/opencontainers/runc.git $GOPATH/src/github.com/opencontainers/runc
  cd $GOPATH/src/github.com/opencontainers/runc
  git fetch origin pull/774/head:rootless-containers
  git checkout rootless-containers
  make BUILDTAGS="seccomp selinux ambient"
  sudo mv runc /usr/local/bin/

  # install umoci
  # https://github.com/cyphar/umoci
  git clone https://github.com/cyphar/umoci.git $GOPATH/src/github.com/cyphar/umoci
  cd $GOPATH/src/github.com/cyphar/umoci
  make
  sudo mv umoci /usr/local/bin/
}
_main() {
  setup_kernel
  install_packages
  install_go
  install_go_projects
}

_main "$@"
