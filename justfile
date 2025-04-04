AGE_RECIPIENT := "age1ff26etr9n8nsp2ve2lkh7w4dqd9g9m9u3y8aw77ureu639mrfatqmuqnhv"
DEFAULT_TALOS_ENDPOINT := "192.168.10.4"

conform *ARGS:
  kubeconform -strict -kubernetes-version 1.29.4 -ignore-missing-schemas kubernetes {{ ARGS }}

lint *ARGS:
  kube-linter lint --exclude latest-tag kubernetes {{ ARGS }}

tal *ARGS:
  talosctl -e {{ DEFAULT_TALOS_ENDPOINT }} {{ ARGS }}

tal-genconfig TALENV='prod':
  SOPS_AGE_KEY_FILE=./sops.agekey talhelper genconfig  -c talos/talconfig.yaml -s "talos/talsecret.{{ TALENV }}.yaml" -e "talos/talenv.{{ TALENV }}.yaml" -o talos/clusterconfig

tal-gencommand-upgrade TALENV='prod':
  SOPS_AGE_KEY_FILE=./sops.agekey talhelper gencommand upgrade -c talos/talconfig.yaml --env-file "talos/talenv.{{ TALENV }}.yaml"


vagrant_run:
  #!/bin/bash

  set -e

  if [ "$EUID" -ne 0 ]
    then echo "Please run as root!"
    exit 1
  fi

  RUN=$(sudo -u "$SUDO_USER" vagrant up 2>&1)
  if [[ "$RUN" =~ "already provisioned" ]]; then
    echo "Already running, stop first with 'vagrant destroy'"
    exit 1
  fi

  echo "Started machines!"

  basename=${PWD##*/}

  echo -n "Waiting for machines to get an address"
  # Wait for machines to get an address
  until virsh domifaddr "$basename"_worker | grep -q "192.168.121"; do
    echo -n .
    sleep 1
  done
  until virsh domifaddr "$basename"_control-plane | grep -q "192.168.121"; do
    echo -n .
    sleep 1
  done

  # Get IP addresses of machines
  WORKER_IP=$(virsh domifaddr "$basename"_worker | grep -Po '(\d+\.){3}\d+')
  CONTROLLER_IP=$(virsh domifaddr "$basename"_control-plane | grep -Po '(\d+\.){3}\d+')

  # Write ephemeral IP to name binding in /etc/hosts
  # NOTE: this works as talos includes node hostnames in the certificate SANs automatically
  sed -i -n -e '/worker/!p' -e '$a'"$WORKER_IP worker" /etc/hosts
  sed -i -n -e '/controller/!p' -e '$a'"$CONTROLLER_IP controller" /etc/hosts

  echo " Machines ready!"

_check_secret_file SECRET_FILE:
  #!/bin/bash

  set -e

  if ! [ -f "{{ SECRET_FILE }}" ]; then
    echo "Error: {{ SECRET_FILE }} does not exists, or it is not a file"
    exit 1
  fi

  KIND=$(yq -r .kind "{{ SECRET_FILE }}")

  if ! [[ "$KIND" == "SopsSecret" ]]; then
    if ! echo "{{ SECRET_FILE }}" | egrep -q "(helm|talos)/"; then
      echo "{{ SECRET_FILE }} is not a SopsSecret, nor a Helm secret"
      exit 1
    fi
  fi

sops SECRET_FILE:
  #!/bin/bash

  set -e

  just _check_secret_file "{{ SECRET_FILE }}"

  SOPS=$(yq -r .sops "{{ SECRET_FILE }}")
  # Not encrypted, missing sops header
  if [[ "$SOPS" == "null" ]]; then
    SOPS_AGE_RECIPIENTS="{{ AGE_RECIPIENT }}" sops --encrypt --in-place "{{ SECRET_FILE }}"
  else
    SOPS_AGE_KEY_FILE=./sops.agekey sops --decrypt --in-place "{{ SECRET_FILE }}"
  fi

ensure-sops SECRET_FILE:
  #!/bin/bash

  set -e

  if ! just _check_secret_file "{{ SECRET_FILE }}"; then
    exit 0
  fi

  SOPS=$(yq -r .sops "{{ SECRET_FILE }}")
  # Not encrypted, missing sops header
  if [[ "$SOPS" == "null" ]]; then
    SOPS_AGE_RECIPIENTS="{{ AGE_RECIPIENT }}" sops --encrypt --in-place "{{ SECRET_FILE }}"
    echo "{{ SECRET_FILE }} is now encrypted!"
  fi

encrypt-all:
  #!/bin/bash

  set -e

  for FILE_PATH in $(find ./helm ./kubernetes -type f -name "*secret*.y?ml"); do
    $(just ensure-sops "$FILE_PATH")
  done

yaml-fix:
  #!/usr/bin/env python3
  import sys, glob

  for filename in glob.iglob("**/*.y*ml", recursive=True):
      with open(filename, "r+") as f:
          content = f.read()
          if not content.startswith('---') and not content.startswith('$ANSIBLE_VAULT'):
              print("Fixed: " + filename)
              f.seek(0)
              f.write('---\n' + content)

format:
  just yaml-fix
  prettier --log-level silent -w 'kubernetes/**/*.y*ml' 'helm/**/*.y*ml' 'apps/**/*.y*ml' 'talos/**/*.yaml'
