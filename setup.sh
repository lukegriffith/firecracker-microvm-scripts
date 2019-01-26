#!/bin/bash

path=/usr/bin/
fc_path=${path}firecracker
jail_path=${path}jailer
latest=0.14.0
nsname='net'

url=https://github.com/firecracker-microvm/firecracker/releases/download/v${latest}/

curl -LOJs ${url}firecracker-v${latest} \
  && echo Firecracker downloaded.
curl -LOJs ${url}jailer-v${latest} \
  && echo Jailer downloaded. 

mv firecracker-v${latest} $fc_path \
  && echo Copied firecracker \
  || echo Failed to copy firecracker to $path.

mv jailer-v${latest} $jail_path \
  && echo Copied jailer \
  || echo Failed to copy jailer to $path.

chmod +x $fc_path && \
chmod +x $jail_path

adduser jailer 2> /dev/null \
  && echo User created. || echo User exists.


ip netns add $nsname

mkdir /opt/firecracker

curl -fsSL -o /opt/firecracker/hello-vmlinux.bin https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin

curl -fsSL -o /opt/firecracker/hello-rootfs.ext4 https://s3.amazonaws.com/spec.ccfc.min/img/hello/fsfiles/hello-rootfs.ext4 

mkdir -p /srv/jailer > /dev/null
chmod 770 /srv/jailer
chown jailer:jailer /srv/jailer \

rm firecracker-v${latest}
rm jailer-v${latest}

echo -e '\033[0;34m'Jailer environment configured.'\033[0m'
