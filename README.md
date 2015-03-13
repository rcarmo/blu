# blu

An exploratory Azure provisioning tool, because the current cross-platform CLI isn't quite what I expected.

## Abstractions

### Project

A project maps to an Azure Cloud Service, and is a modal context that acts as a resource group for VMs, storage, etc.

### Network

TBC

### Virtual Machine



### User

One or more SSH keys to provision remotely for access.

### Role

In KISS style, a role is an OS image and a set of base packages to install after provisioning.

## Commands (To Be Implemented)

* init
* project (list, create, destroy, etc.)
* vm (list, create, destroy, etc.)
    * vnet (list)
    * disk (list, add, remove)
* role (list, create, destroy, etc.)
* user (list, create, destroy, add, remove)
