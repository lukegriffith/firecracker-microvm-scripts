#!/bin/bash

# $1 is microvm id


# paths.
boot_rt='/srv/jailer/firecracker/'$1
sock=$boot_rt'/api.socket'
source_rt='/opt/firecracker/'

# image and filesystem files. 
rootfs='./hello-rootfs.ext4'
kernel_bin='./hello-vmlinux.bin'
kernel_args=''

# named pipe configuration
logs_fifo=$boot_rt'/root/logs'
metrics_fifo=$boot_rt'/root/metrics'


# network configuration 
network_namespace="net"
tap_device="tap_$1"


mask_long="255.255.255.0"
mask_short="/24"

guest_ip="10.1.$(( 16#${1:0:2} )).$(( 16#${1:2:3} ))"
guest_mac="10:FC:00:A0:${1:0:2}:${1:2:3}"

echo "guest_mac $guest_mac"


echo "Starting microvm...

Boot root is $boot_rt
API socket $sock
"

# setting up microvm

ln $source_rt/hello-vmlinux.bin $boot_rt/root/hello-vmlinux.bin 2> /dev/null \
  && echo "Linked vmlinux binary to $1." \
  || echo "Binary already linked."


# no clobber copy of the root filesystem

cp -n /opt/firecracker/hello-rootfs.ext4 $boot_rt/root/hello-rootfs.ext4 


# make fifo pipes for logging

mkfifo -m a=rw $logs_fifo  2> /dev/null \
  && echo "Created logs fifo pipe for $1" \
  || echo "Failed to create logs fifo pipe for $1, already exists?" 


mkfifo -m a=rw $metrics_fifo 2> /dev/null \
  && echo "Created metrics fifo pipe for $1" \
  || echo "Failed to create metrics fifo pipe for $1, already exists?" 


# configuring ownership

chown -R jailer:jailer $boot_rt \
  || echo "Failed to configure boot root ownership for $1."

# creating and configure network tap devices

ip tuntap add dev $tap_device user jailer group jailer mode tap
ip link set $tap_device netns $network_namespace
ip netns exec $network_namespace ip addr add dev "${tap_device} "${guest_ip}${mask_short}" "
ip netns exec $network_namespace ip link set dev "${tap_device}" up
ip netns exec $network_namespace sysctl -w net.ipv4.conf.${tap_device}.proxy_arp=1 > /dev/null
ip netns exec $network_namespace sysctl -w net.ipv6.conf.${tap_device}.disable_ipv6=1 > /dev/null

# set boot image

echo

curl --unix-socket $sock -s -i \
    -X PUT 'http://localhost/boot-source'   \
    -H 'Accept: application/json'           \
    -H 'Content-Type: application/json'     \
    -d '{
        "kernel_image_path": "'$kernel_bin'",
        "boot_args":"console=tty50 reboot=k panic=1 pci=off ipv6.disable=1"
    }' 
  

# set root filesystem

echo

curl --unix-socket $sock -s -i \
    -X PUT 'http://localhost/drives/rootfs' \
    -H 'Accept: application/json'           \
    -H 'Content-Type: application/json'     \
    -d '{
        "drive_id": "rootfs",
        "path_on_host": "'$rootfs'",
        "is_root_device": true,
        "is_read_only": false
    }' 

# configure logger

echo 

curl --unix-socket $sock -s -i \
    -X PUT 'http://localhost/logger' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
        "log_fifo": "./logs", 
        "metrics_fifo": "./metrics", 
        "level": "Error", 
        "show_level": true, 
        "show_log_origin": false
    }'

# configure network device

echo 

curl --unix-socket $sock -s -i \
     -X PUT 'http://localhost/network-interfaces/0' \
     -H 'accept: application/json' \
     -H 'Content-Type: application/json' \
     -d '{
          "iface_id": "0",
          "guest_mac":"'$guest_mac'",
          "host_dev_name": "'$tap_device'",
          "allow_mmds_requests": true
        }'

# start machine

echo

curl --unix-socket $sock -s -i \
    -X PUT 'http://localhost/actions'       \
    -H  'Accept: application/json'          \
    -H  'Content-Type: application/json'    \
    -d '{
        "action_type": "InstanceStart"
    }'


