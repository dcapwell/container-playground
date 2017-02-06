# Build

```
docker build -t oci/playground .
docker run -ti --privileged --security-opt seccomp=unconfined oci/playground bash
```

# Running

```
mkdir -p /tmp/playground
cd /tmp/playground/
skopeo copy docker://centos oci:centos
mkdir centos-bundle
oci-create-runtime-bundle --ref latest centos centos-bundle/
cd centos-bundle/
  rm -f config.json 
  runc spec
cd -
oci-runtime-tool generate \
  --tty \
  --bind /etc/resolv.conf:/etc/resolv.conf \
  --template centos-bundle/config.json > centos-bundle/config.json.tmp
mv -f centos-bundle/config.json{.tmp,}
runc run -b centos-bundle/ ctr
```

If `runc` fails with `container_linux.go:247: starting container process caused "process_linux.go:283: applying cgroup configuration for process caused \"mountpoint for cgroup not found\""` then execute `https://raw.githubusercontent.com/tianon/cgroupfs-mount/master/cgroupfs-mount` and rerun.  This means that the cgroup mounts were not added to the container, so just need to add them manually.

# Running without root

As of Ubunt 14.04, this doesn't work; testing on RHEL 7 is needed to see if it works there.

## Prerequisites

User Namespaces (http://man7.org/linux/man-pages/man7/user_namespaces.7.html) are required for this
to work.  This allows for a container to run with `uid=0` but run as the mapped user on the host
(most likely the user launching the container).

Many distributions will not enable this feature by default, so it may need to be configured. To
check if its setup, check `cat /proc/cmdline` to see if `user_namespaces.enable=1` is found. If
not found, update grub configurations to enable it (requires restart).

## Running

```
useradd notroot
# allow all users to write to runc data
mkdir -p /run/runc
chmod a+rwx /run/runc/
su - notroot
mkdir -p /tmp/rootless-playground
cd /tmp/rootless-playground
skopeo copy docker://centos oci:centos
umoci unpack --rootless --image centos:latest centos-bundle
cd centos-bundle/
  rm -f config.json 
  runc spec --rootless
cd -
oci-runtime-tool generate \
  --tty \
  --template centos-bundle/config.json > centos-bundle/config.json.tmp
mv -f centos-bundle/config.json{.tmp,}
runc run -b centos-bundle/ rootlessctr
```
