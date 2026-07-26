AGE_RECIPIENT := "age1ff26etr9n8nsp2ve2lkh7w4dqd9g9m9u3y8aw77ureu639mrfatqmuqnhv"
DEFAULT_TALOS_ENDPOINT := "192.168.10.4"

init:
  pre-commit install
  pre-commit install --hook-type commit-msg

tal *ARGS:
  talosctl --talosconfig talos/clusterconfig/talosconfig {{ ARGS }}

tal-genconfig:
  SOPS_AGE_KEY_FILE=./sops.agekey talhelper genconfig  -c talos/talconfig.yaml -s talos/talsecret.sops.yaml -e talos/talenv.yaml -o talos/clusterconfig
  chmod 600 talos/clusterconfig/*

tal-gencommand-upgrade:
  SOPS_AGE_KEY_FILE=./sops.agekey talhelper gencommand upgrade -c talos/talconfig.yaml -e talos/talenv.yaml -o talos/clusterconfig

_check_secret_file SECRET_FILE:
  #!/bin/bash

  set -e

  if ! [ -f "{{ SECRET_FILE }}" ]; then
    echo "Error: {{ SECRET_FILE }} does not exists, or it is not a file"
    exit 1
  fi

  KIND=$(yq -r .kind "{{ SECRET_FILE }}")

  if ! [[ "$KIND" == "SopsSecret" ]]; then
    if ! echo "{{ SECRET_FILE }}" | grep -Eq "(helm|talos)/"; then
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

  if ! head -n 1 "{{ SECRET_FILE }}" | grep -q '^---$'; then
    (echo "---"; cat "{{ SECRET_FILE }}") > "{{ SECRET_FILE }}.tmp"
    mv "{{ SECRET_FILE }}.tmp" "{{ SECRET_FILE }}"
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
    just sops "{{ SECRET_FILE }}"
    echo "{{ SECRET_FILE }} is now encrypted!"
  fi

encrypt-all:
  #!/bin/bash

  set -e

  for FILE_PATH in $(find ./helm ./kubernetes ./talos -type f -name "*.sops.y?ml"); do
    just ensure-sops "$FILE_PATH"
  done

debug-pod NAMESPACE:
  kubectl run -n {{ NAMESPACE }} -it --rm --restart=Never --image=infoblox/dnstools:latest debug

pvc-pod NAMESPACE PVC:
  #!/bin/bash

  set -e

  cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      namespace: {{ NAMESPACE }}
      name: debug
    spec:
      containers:
        - name: debug
          image: alpine:latest
          command:
            - sleep
            - infinity
          volumeMounts:
            - name: pvc
              mountPath: /mnt
      volumes:
        - name: pvc
          persistentVolumeClaim:
            claimName: {{ PVC }}
      restartPolicy: Never
  EOF

[arg('apply', short='a', long='apply', value='true')]
kust PATH apply='':
    kubectl kustomize "{{ PATH }}" --enable-helm {{ if apply != '' { '| kubectl apply -f -' } else { '' } }}
