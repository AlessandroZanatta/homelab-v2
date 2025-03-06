# kalexlab - GitOps Homelab

## Overview

This repository keeps all the Infrastructure as Code (IaC) for my homelab, composed of:

- HP EliteDesk 800 G3M i7-6700T and 16G DDR4 (192.168.10.4)
- Dell Optiplex 3050M with i5-6600T and 16G DDR4 (192.168.10.3)
- TP-Link Archer AX23

The TP-Link router has OpenWRT installed, and is also used for remote access via Wireguard.

Cluster nodes use Talos to spin up a Kubernetes cluster. A small ansible playbook is used to make the nodes ready (i.e. install Cilium, CoreDNS and ArgoCD).
When nodes are ready, the `bootstrap/app-of-apps.yaml` manifest is used to install all the ArgoCD applications, finalizing the cluster setup.

## Folder structure

The following is a general overview of the folders:

- [ansible](ansible): everything related to Ansible
  - [playbooks](ansible/playbooks)
    - [cluster](ansible/playbooks/cluster): contains the Ansible playbook used to boostrap a Talos cluster with CNI, DNS and ArgoCD
    - [openwrt](ansible/playbooks/openwrt): setups the router with the Wireguard VPN, allowing remote access to LAN, including cluster applications
- [apps](apps): includes all the ArgoCD applications(sets) manifests, used to manage the cluster via GitOps
- [bootstrap](bootstrap): has a single resource that bootstraps the cluster applications with the [app-of-apps](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/) ArgoCD pattern
- [helm](helm): contains the values, as well as related extra manifests, for Helm charts (deployed by ArgoCD)
- [kubernetes](kubernetes): contains the manifests for most of the applications I daily use on the cluster
- [talos](talos): keeps the [talhelper](https://github.com/budimanjojo/talhelper) configuration file

## Development cluster

In order to keep an up-to-date and working development cluster, I setup an [ArgoCD cluster secret](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters) when bootstrapping the Talos cluster, and use the labels on this cluster secret in ArgoCD applications to properly choose the correct Kustomize patches and Helm values files.

First, in Ansible, the environment decides whether to build the talos configuration using [talenv.prod.yaml](talos/talenv.prod.yaml) or [talenv.dev.yaml](talos/talenv.dev.yaml). This is used in [env.yaml](talos/patches/cluster/env.yaml) to create a secret for the cluster containing a label `env` with the value from the chosen talenv.

Then, in ArgoCD ApplicationSets, you can use this label to define the paths/files to be used by the application with the [clusters generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/). For example, longhorn uses the following ApplicationSet definition:

```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: longhorn
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]

  # Use the clusters generator to access the label setup previously
  generators:
    - clusters: {}
  template:
    metadata:
      name: longhorn
    spec:
      project: default
      sources:
        - repoURL: "https://charts.longhorn.io"
          chart: longhorn
          targetRevision: 1.*
          helm:
            releaseName: longhorn
            valueFiles:
              - $values/helm/longhorn/values.yaml

              # Here we can use a little bit of templating to specify which values we want to use
              - $values/helm/longhorn/values-{{ .metadata.labels.env }}.yaml
        - repoURL: "https://github.com/AlessandroZanatta/homelab-v2.git"
          targetRevision: master

          # As well as the extra manifests (see below)
          path: "helm/longhorn/extra/overlays/{{ .metadata.labels.env }}"
          ref: values
        - repoURL: "https://github.com/AlessandroZanatta/homelab-v2.git"
          targetRevision: master
          path: "helm/longhorn/patches/{{ .metadata.labels.env }}"
      destination:
        server: "{{ .server }}"
        namespace: longhorn-system
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

The [longhorn](helm/longhorn) Helm values are then structured as following:

- [values.yaml](helm/longhorn/values.yaml): contains the base values
- [values-prod.yaml](helm/longhorn/values-prod.yaml): contains the additional values to be used for production (in this case, disables storage over provisioning)
- [values-dev.yaml](helm/longhorn/values-dev.yaml): as above, but with development values (enables storage over provisioning to simulate a large enough storage per-node)
- [extra](helm/longhorn/extra): keeps the additional manifests to be deployed with Longhorn (e.g. an ingress for the dashboard)
  - [base](helm/longhorn/extra/base): base manifests
  - [overlays/dev](helm/longhorn/extra/overlays/dev): Kustomize patches used to enable deploying on a development cluster without disruption (e.g. changes DNS name)
  - [overlays/prod](helm/longhorn/extra/overlays/prod): usually just a basic kustomize file referencing base manifests
- [patches](helm/longhorn/patches): contains the patches for other resources not managed by Kustomize (e.g. `nodes.longhorn.io` resources). As extra manifests, patches are also divided between development and production

### Creating the development cluster

> [!NOTE]
> The following steps assume you have replaced **ALL** the encrypted secrets with your own generated `sops.agekey` in the root of this repository
> Note that, at the very least, you should generate a new [talsecret.yaml](talos/talsecret.yaml) file

> [!IMPORTANT]
> The development environment requires quite a bit of RAM (~16GB)

Prerequisites:

- `vagrant` with the `vagrant-libvirt` plugin
- `justfile`
- `talhelper`
- `talosctl`
- `kubectl`

To spin up two VMs it is sufficient to execute the following commands:

```
# Download Talos ISO image
mkdir images && cd images && wget https://github.com/siderolabs/talos/releases/download/v1.9.2/metal-amd64.iso && cd ..

# Create nodes
sudo just vagrant_run

# Bootstrap essential components (CNI, DNS, ArgoCD)
cd ansible && ansible-playbook -i environments/dev playbooks/cluster/bootstrap.yaml && cd ..

# Finalize bootstrapping with ArgoCD apps
kubectl apply -f ./bootstrap/app-of-apps.yaml
```

Then all you need to do is... wait. Eventually, all the cluster's applications should be up and running!

> [!WARNING]
> Currently, spinning the development environment causes Talos discovery to join the development and production nodes, which could end up badly.
> I still need to find a solution, but using a different talsecrets.yaml file should be sufficient.
