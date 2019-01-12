#!/bin/bash

# $1 is microvm id


# paths.
boot_rt='/srv/jailer/firecracker/'$1
sock=$boot_rt'/api.socket'
source_rt='/opt/firecracker/'

# image and filesystem files. 
rootfs='./hello-rootfs.ext4'
kernel_bin='./hello-vmlinux.bin'


# named pipe configuration
logs_fifo=$boot_rt'/root/logs'
metrics_fifo=$boot_rt'/root/metrics'


# network configuration 
network_namespace="net"
tap_device="tap_$1"

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

# creating network tap devices

ip tuntap add user jailer group jailer name $tap_device mode tap
ip link set dev $tap_device netns $network_namespace

guest_mac=ip link show $tap_device | grep link/ether \
  | awk '{print $2}'

# set boot image

echo

curl --unix-socket $sock -s -i \
    -X PUT 'http://localhost/boot-source'   \
    -H 'Accept: application/json'           \
    -H 'Content-Type: application/json'     \
    -d '{
        "kernel_image_path": "'$kernel_bin'",
        "boot_args": "console=ttyS0 reboot=k panic=1 pci=off ip=10.1.1.10/24"
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


