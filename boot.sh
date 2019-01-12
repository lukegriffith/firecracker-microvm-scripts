#!/bin/bash


id=$1
firecracker='/usr/bin/firecracker'
netns='/var/run/netns/net'

/usr/bin/jailer --id $id \
       --node 0 \
       --exec-file $firecracker \
       --uid 1004 \
       --gid 1006 \
       --netns $netns

