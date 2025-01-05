AGE_RECIPIENT := "age1ff26etr9n8nsp2ve2lkh7w4dqd9g9m9u3y8aw77ureu639mrfatqmuqnhv"

conform *ARGS:
  kubeconform -strict -kubernetes-version 1.29.4 -ignore-missing-schemas playbooks/cluster/templates/manifests {{ ARGS }}

lint *ARGS:
  kube-linter lint --exclude latest-tag playbooks/cluster/templates/manifests {{ ARGS }}

apply FILTER:
  ansible-playbook -i environments/prod playbooks/cluster/k8s-apps.yaml -t apply -e 'filter={{ FILTER }}'

delete FILTER:
  ansible-playbook -i environments/prod playbooks/cluster/k8s-apps.yaml -t delete -e 'filter={{ FILTER }}'

_check_secret_file SECRET_FILE:
  #!/bin/bash

  set -e

  if ! [ -f "{{ SECRET_FILE }}" ]; then
    echo "Error: {{ SECRET_FILE }} does not exists, or it is not a file"
    exit 1
  fi

  KIND=$(yq -r .kind "{{ SECRET_FILE }}")

  if ! [[ "$KIND" == "SopsSecret" ]]; then
    if ! echo "{{ SECRET_FILE }}" | grep -q "helm/"; then
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

  just _check_secret_file "{{ SECRET_FILE }}"

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
