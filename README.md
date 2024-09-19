# Homelab

This repository keeps all the Infrastructure as Code (IaC) for my homelab, composed of:

- Dell Optiplex 3050M with i5-6600T and 16G
- Raspberry PI 4B
- TP-Link Archer AX23

I use Ansible to configure both machines and to create a Kubernetes cluster "the hard way".
The Optiplex acts as a worker for the Kubernetes cluster.
Control plane processes are handled by the Raspberry, which is completely stateless.
The etcd cluster has a single replica on the Optiplex, which has two disks configured in RAID 1.

## Folder structure

The following is a general overview of the folders:

- `environments` keeps the two environments used by ansible, one for testing (hosted on my computer using vagrant), and one for production (targets the physical machines)
- `files` keeps generic files that are to be copied as-is by Ansible
- `playbooks` is where Ansible playbooks live. It contains all the playbooks used to configure the cluster and the router.
  - `cluster` folder contains all the playbooks to configure the cluster, such as bootstrapping the nodes after a very basic (manual 😔) installation, creating a mesh network for the nodes to communicate on, creating an etcd cluster, running worker and control plane processes on (the correct) nodes, and much much more!
    - `templates` contains the actual definition for the Kubernetes workloads. In particular it is split among `helm`, which I try to keep in use only for the critical services (e.g. Kubernetes network mesh, cluster DNS, persistent volumes handling, certificates provisioning, and load balancing), and `manifests`, which keeps the actual Kubernetes
  - `openwrt` mainly contains the Wireguard configuration for the router, which uses OpenWrt. In my setup, services are only accessible on the (W)LAN network. In order to access them from the outside world, the router terminates the VPN connection, allowing to seamlessly accessing the local network remotely. Terminating the VPN connection on the router is especially useful when you want to access your home network from outside (e.g. for updating stuff). Moreover, Archer AX23 should have hardware acceleration for WireGuard, as long as advertisements do not lie (and openwrt supports it).
- `roles` contains many Ansible roles. These roles are used to de-compose different steps of the homelab configuration in smaller, (hopefully) understandable components.
- `outputs` keeps the (many) outputs of Ansible. It is divided based on the Ansible environment. It contains cluster certificates, Wireguard configurations, and the admin kubeconfig. For obvious reasons, it is ignored by git.

## Cluster overview

A cluster overview is document in (docs/homelab.png)[homelab.png]. It is a high level view of what is going in inside the cluster.
