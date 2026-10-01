init:
  pre-commit install
  pre-commit install --hook-type commit-msg

tal *ARGS:
  talosctl --talosconfig topf/talosconfig {{ ARGS }}

[working-directory('topf')]
topf *ARGS:
  topf {{ ARGS }}

[working-directory('topf')]
topf-talosconfig:
  topf talosconfig > talosconfig

_check_secret_file SECRET_FILE:
  #!/bin/bash

  set -euo pipefail

  if ! [ -f "{{ SECRET_FILE }}" ]; then
    echo "Error: {{ SECRET_FILE }} does not exists, or it is not a file"
    exit 1
  fi

  KIND=$(yq -r .kind "{{ SECRET_FILE }}")

  if ! [[ "$KIND" == "SopsSecret" ]]; then
    if ! echo "{{ SECRET_FILE }}" | grep -Eq "(helm|topf)/"; then
      echo "{{ SECRET_FILE }} is not a SopsSecret, nor a Helm secret"
      exit 1
    fi
  fi

sops SECRET_FILE:
  #!/bin/bash

  set -euo pipefail

  just _check_secret_file "{{ SECRET_FILE }}"

  SOPS=$(yq -r .sops "{{ SECRET_FILE }}")
  # Not encrypted, missing sops header
  if [[ "$SOPS" == "null" ]]; then
    sops --encrypt --in-place "{{ SECRET_FILE }}"
  else
    sops --decrypt --in-place "{{ SECRET_FILE }}"
  fi

  if ! head -n 1 "{{ SECRET_FILE }}" | grep -q '^---$'; then
    (echo "---"; cat "{{ SECRET_FILE }}") > "{{ SECRET_FILE }}.tmp"
    mv "{{ SECRET_FILE }}.tmp" "{{ SECRET_FILE }}"
  fi

ensure-sops SECRET_FILE:
  #!/bin/bash

  set -euo pipefail

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

  set -euo pipefail

  for FILE_PATH in $(find ./helm ./kubernetes ./topf -type f -name "*.sops.y?ml"); do
    just ensure-sops "$FILE_PATH"
  done

debug-pod NAMESPACE:
  kubectl run -n {{ NAMESPACE }} -it --rm --restart=Never --image=infoblox/dnstools:latest debug

pvc-pod NAMESPACE PVC:
  #!/bin/bash

  set -euo pipefail

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
