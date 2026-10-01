# kalexlab - GitOps Homelab

## Overview

This repository keeps all the Infrastructure as Code (IaC) for my homelab, composed of:

| Host   | Hardware                                 | IP           | Role                            |
| ------ | ---------------------------------------- | ------------ | ------------------------------- |
| zeus   | HP EliteDesk 800 G3M, i7-6700T, 16G DDR4 | 192.168.10.4 | Control plane (schedulable)     |
| hermes | Dell Optiplex 3050M, i5-6600T, 16G DDR4  | 192.168.10.3 | Worker                          |
| athena | Raspberry Pi 4B, 4G                      | 192.168.10.2 | Worker, VPN egress gateway      |
| -      | TP-Link Archer AX23 (OpenWRT)            | 192.168.10.1 | Router, WireGuard remote access |

The Kubernetes API is exposed on the control plane VIP `192.168.10.9`.

Cluster nodes run [Talos](https://www.talos.dev/), whose configuration is managed with [topf](topf). Secrets are encrypted with [SOPS](https://github.com/getsops/sops) using an AGE key.

Once the cluster is up and running, the [app-of-apps](bootstrap/app-of-apps.yaml) manifest installs all the ArgoCD applications, finalizing the cluster setup:

```sh
kubectl apply -f ./bootstrap/app-of-apps.yaml
```

> [!NOTE]
> TODO: document the cluster bootstrap procedure. After the migration from talhelper to topf, the [cluster bootstrap playbook](ansible/playbooks/cluster/bootstrap.yaml) (which installs Cilium, CoreDNS and ArgoCD) still references the old `talos/` and `helm/` folders and needs to be reworked.

## Folder structure

- [ansible](ansible): everything related to Ansible
  - [playbooks/openwrt](ansible/playbooks/openwrt): sets up the router with the WireGuard VPN (remote access to the LAN, including cluster applications) and the egress VPN (see [Cluster VPN](#cluster-vpn))
  - [playbooks/cluster](ansible/playbooks/cluster): cluster bootstrap playbook (outdated, see the note above)
  - [roles/wireguard-mesh](ansible/roles/wireguard-mesh): role to set up a WireGuard mesh
- [apps](apps): ArgoCD `Application` manifests, one per application, grouped by category (`apps`, `management`, `misc`, `monitoring`). Each one points to the matching `kubernetes/<category>/<app>` folder
- [bootstrap](bootstrap): a single resource that bootstraps all the cluster applications with the [app-of-apps](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/) ArgoCD pattern, recursing into `apps`
- [kubernetes](kubernetes): the Kustomize bases for all the applications deployed on the cluster
- [topf](topf): the Talos configuration
  - [topf.yaml](topf/topf.yaml): cluster definition (Talos/Kubernetes versions, nodes, per-node data such as disks, labels and taints)
  - [all](topf/all), [control-plane](topf/control-plane), [worker](topf/worker), [node](topf/node): config patches applied to all nodes, by role, or to specific nodes
  - [schematic.yaml.tpl](topf/schematic.yaml.tpl): the Talos Image Factory schematic

### Application layout

Every application under [kubernetes](kubernetes) follows the same structure:

```
kubernetes/<category>/<app>/
├── kustomization.yaml   # entrypoint, optionally including Helm charts
├── manifests/           # plain manifests (ingresses, secrets, extra resources, ...)
├── patches/             # patches to kustomization-rendered manifests, if any
└── values/              # Helm values, if any Helm chart is used
```

Helm charts are rendered by Kustomize through the `helmCharts` field (ArgoCD runs with `kustomize.buildOptions: --enable-helm`), and are cached locally in `.charts`. For example, [longhorn](kubernetes/management/longhorn/kustomization.yaml):

```yaml
helmGlobals:
  chartHome: ../../../.charts

helmCharts:
  - name: longhorn
    repo: https://charts.longhorn.io
    version: 1.13.0
    releaseName: longhorn
    namespace: longhorn-system
    valuesFile: values/longhorn.yaml

resources:
  - manifests
```

Secrets are stored next to the other manifests as `*.sops.yaml` files, encrypted with SOPS (see [.sops.yaml](.sops.yaml)).

## Tooling

Common tasks are available as [just](https://github.com/casey/just) recipes in the [justfile](justfile):

| Recipe                    | Description                                                    |
| ------------------------- | -------------------------------------------------------------- |
| `just init`               | Install the pre-commit hooks                                   |
| `just topf <args>`        | Run `topf` from the `topf` folder                              |
| `just topf-talosconfig`   | Generate the `talosconfig` file                                |
| `just tal <args>`         | Run `talosctl` with the generated `talosconfig`                |
| `just sops <file>`        | Toggle encryption of a secret file                             |
| `just encrypt-all`        | Ensure all `*.sops.yaml` files are encrypted                   |
| `just kust <path> [-a]`   | Render a Kustomize folder (with Helm), and optionally apply it |
| `just debug-pod <ns>`     | Start a throwaway pod with DNS/network tools                   |
| `just pvc-pod <ns> <pvc>` | Start a pod mounting the given PVC on `/mnt`                   |

[pre-commit](.pre-commit-config.yaml) hooks run yamllint, enforce [Conventional Commits](https://www.conventionalcommits.org/), and prevent committing unencrypted secrets. Dependencies (container images, Helm charts, Talos/Kubernetes versions) are kept up to date by [Renovate](renovate.json).

## Cluster VPN

For increased privacy, it is possible to ensure selected pods route their egress traffic through a VPN.

In order for a pod to be routed through the VPN, it needs to have the following label: `egress.kalexlab.xyz/policy: vpn`.

The VPN is implemented as following:

- Cilium's [EgressGateway](https://docs.cilium.io/en/stable/network/egress-gateway/egress-gateway/), configured in [egress-gateway.yaml](kubernetes/misc/egress-vpn/manifests/egress-gateway.yaml), redirects the egress traffic from pods with the above label through the node labeled `egress.kalexlab.xyz/gateway: vpn` (`athena`, see [topf.yaml](topf/topf.yaml)). The node is also tainted with `kalexlab.xyz/taint=vpn:NoSchedule`, so that regular workloads are not scheduled on it
- On the router, an WireGuard interface is configured
- Finally, still on the router, Policy-based Routing is applied to the `athena` node's IP. The rule routes all the non-local traffic through the VPN interface
