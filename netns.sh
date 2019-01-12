#!/bin/bash

tap_name='tap2'

ip tuntap add user jailer group jailer name $tap_name mode tap
ip link set $tap_name netns net

ip netns exec net ifconfig $tap_name 10.1.1.1 up netmask 255.255.255.0

