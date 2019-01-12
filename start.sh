#!/bin/bash

# $1 is microvm id

boot_rt='/srv/jailer/firecracker/'$1'/'
sock=$boot_rt'api.socket'
rootfs='./hello-rootfs.ext4'
kernel_bin='./hello-vmlinux.bin'
source_rt='/opt/firecracker/'
logs_fifo=$boot_rt'/root/logs'
metrics_fifo=$boot_rt'/root/metrics'


echo "Starting microvm...

Boot root is $boot_rt
API socket $sock
"

# setting up microvm

ln $source_rt/hello-vmlinux.bin $boot_rt/root/hello-vmlinux.bin 2> /dev/null \
  && echo "Linked vmlinux binary to $1." \
  || echo "Binary already linked."


# no clobber copy of the root filesystem

cp -n /opt/firecracker/hello-rootfs.ext4 $boot_rt/root/hello-rootfs.ext4 \


# make fifo pipes for logging

mkfifo -m a=rw $logs_fifo
mkfifo -m a=rw $metrics_fifo

# configuring ownership

chown -R jailer:jailer $boot_rt \
  || echo "Failed to configure boot root ownership for $1."

# set boot image

echo

curl --unix-socket $sock -s \
    -X PUT 'http://localhost/boot-source'   \
    -H 'Accept: application/json'           \
    -H 'Content-Type: application/json'     \
    -d '{
        "kernel_image_path": "'$kernel_bin'",
        "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
    }' | jq 
  

# set root filesystem

echo

curl --unix-socket $sock -s \
    -X PUT 'http://localhost/drives/rootfs' \
    -H 'Accept: application/json'           \
    -H 'Content-Type: application/json'     \
    -d '{
        "drive_id": "rootfs",
        "path_on_host": "'$rootfs'",
        "is_root_device": true,
        "is_read_only": false
    }' | jq 

# configure logger

echo 

curl --unix-socket $sock -s \
    -X PUT 'http://localhost/logger' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
        "log_fifo": "./logs", 
        "metrics_fifo": "./metrics", 
        "level": "Error", 
        "show_level": true, 
        "show_log_origin": false
    }' | jq 

# start machine

echo

curl --unix-socket $sock -s \
    -X PUT 'http://localhost/actions'       \
    -H  'Accept: application/json'          \
    -H  'Content-Type: application/json'    \
    -d '{
        "action_type": "InstanceStart"
    }' | jq 


