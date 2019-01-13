#!/bin/bash


id=$1
nsname='net'
firecracker='/usr/bin/firecracker'
netns="/var/run/netns/$nsname"
tap_device="tap_$id"

echo
echo "Started boot for $id"

/usr/bin/jailer --id $id \
       --node 0 \
       --exec-file $firecracker \
       --uid 1004 \
       --gid 1006 \
       --netns $netns \
       || exit 0

rm -rf "/srv/jailer/firecracker/$id"

ip netns exec $nsname ip link del $tap_device 
ip tuntap del $tap_device mode tap
