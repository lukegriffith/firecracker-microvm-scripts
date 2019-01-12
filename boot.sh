#!/bin/bash


id=$1
firecracker='/usr/bin/firecracker'
netns='/var/run/netns/net'
tap_device="tun_$id"

echo
echo "Started boot for $id"

/usr/bin/jailer --id $id \
       --node 0 \
       --exec-file $firecracker \
       --uid 1004 \
       --gid 1006 \
       --netns $netns

rm -rf "/srv/jailer/firecracker/$id"
ip tuntap del $tap_device mode tap
