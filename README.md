# firecracker-scripts
Scripts to aid in the use of Firecracker.

## boot
Script creates a microvm and attached to the existing terminal, this exposes an api server socket under ```/srv/jailer```.

boot assumes a jailer user and group have been created with the uid of 1004 and the gid of 1006, these need rwx access to ```/opt/firecracker``` and ```/srv/jailer```. A network namespace should be created called net.

```sudo ip netns add net```

## start
Script links the linux vm binary and copies a fresh root file system. Sends HTTP requests to the microvm api server, an configures it to boot.

### Arguments
boot and start both take the same single argument, the identification of the vm. 

- id: identification for the vm.

