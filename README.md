# firecracker-scripts
Scripts to aid in the use of Firecracker.

## boot
Script creates a microvm and attached to the existing terminal, this exposes an api server socket under ```/srv/jailer```.

boot assumes a jailer user and group have been created with the uid of 1004 and the gid of 1006, these need rwx access to ```/opt/firecracker``` and ```/srv/jailer```. A network namespace should be created called net.

```sudo ip netns add net```

## start
Script links the linux vm binary and copies a fresh root file system. Sends HTTP requests to the microvm api server, and configures it to boot.

a linux kernel binary, and a ext4 root filesystem should be located under /opt/firecracker. If unsure on what these are follow the [getting started documentation](https://github.com/firecracker-microvm/firecracker/blob/master/docs/getting-started.md#running-firecracker).

### Arguments
boot and start both take the same single argument, the identification of the vm. 

- id: identification for the vm.



