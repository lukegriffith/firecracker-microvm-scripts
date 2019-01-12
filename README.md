# firecracker-scripts
Scripts to aid in the use of Firecracker.

## boot
Script creates a microvm and attached to the existing terminal, this exposes an api server socket under /srv/jailer.

## start
Script links the linux vm binary and copies a fresh root file system. Sends HTTP requests to the microvm api server, an configures it to boot.

### Arguments
boot and start both take the same single argument, the identification of the vm. 

- id: identification for the vm.

