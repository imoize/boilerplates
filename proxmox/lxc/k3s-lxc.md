# Script for setup requirement installing K3s on Proxmox LXC

## Introduction
You can fetch this [script](./scripts/k3s-lxc.sh), and then execute it locally. You can read through it and understand what it is doing before you run it.

This installer script that will automatically setup requirement for installing k3s on lxc. This script will install **`Helm`** [package manager for Kubernetes.](https://helm.sh/)

And make sure that /dev/kmsg exists. Kubelet uses this for some logging functions, and it doesn’t exist in the lxc by default.

## Installation

NOTE: This script requires superuser privileges.

To grab this script run this following command

```bash
wget -qO k3s-lxc.sh https://raw.githubusercontent.com/imoize/boilerplates/master/proxmox/lxc/scripts/k3s-lxc.sh
```

Make file executable
```bash
sudo chmod +x k3s-lxc.sh
```

Finally run
```bash
sudo ./k3s-lxc.sh
```

## Uninstalling

If you want remove or uninstall simply just run this command and reboot

```bash
sudo ./k3s-lxc.sh -u
```