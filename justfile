openwrt_router := "192.168.10.1"

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
    if ! echo "{{ SECRET_FILE }}" | grep -Eq "(helm|topf|openwrt)/"; then
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

  for FILE_PATH in $(find ./helm ./kubernetes ./topf ./openwrt -type f -name "*.sops.y?ml"); do
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

# Beware, the *openwrt* commands are complete slop :)
# Render openwrt/files into OUT, replacing ${VAR} with values from openwrt/secrets.sops.yaml
_openwrt-render OUT:
  #!/bin/bash

  set -euo pipefail

  VARS=""
  if [ -f openwrt/secrets.sops.yaml ]; then
    SECRETS=$(sops -d --output-type dotenv openwrt/secrets.sops.yaml)
    while IFS= read -r LINE; do
      [ -n "$LINE" ] || continue
      KEY="${LINE%%=*}"
      export "$KEY=${LINE#*=}"
      VARS="$VARS \$$KEY"
    done <<< "$SECRETS"
  fi

  cd openwrt/files
  find . -type f ! -name .gitkeep | while read -r FILE; do
    mkdir -p "{{ OUT }}/$(dirname "$FILE")"
    if [ -n "$VARS" ]; then
      envsubst "$VARS" < "$FILE" > "{{ OUT }}/$FILE"
    else
      cp "$FILE" "{{ OUT }}/$FILE"
    fi
  done

  if UNRESOLVED=$(grep -rlE '\$\{[A-Za-z_][A-Za-z0-9_]*\}' "{{ OUT }}"); then
    echo "Unresolved placeholders in: $UNRESOLVED" >&2
    exit 1
  fi

# Show differences between rendered openwrt/files and the router
openwrt-diff:
  #!/bin/bash

  set -euo pipefail

  OUT=$(mktemp -d)
  trap 'rm -rf "$OUT"' EXIT
  just _openwrt-render "$OUT"

  cd "$OUT"
  for FILE in $(find . -type f | sed 's|^\./||' | sort); do
    ssh {{ openwrt_router }} "sudo cat /$FILE 2>/dev/null || true" \
      | diff -u --label "router:/$FILE" --label "repo:/$FILE" - "$FILE" --color \
    || true
  done

# Push rendered openwrt/files to the router; rolls back unless confirmed within TIMEOUT seconds
openwrt-apply TIMEOUT="90":
  #!/bin/bash

  set -euo pipefail

  if (( {{ TIMEOUT }} < 45 )); then
    echo "TIMEOUT must be at least 45 seconds" >&2
    exit 1
  fi

  OUT=$(mktemp -d)
  trap 'rm -rf "$OUT"' EXIT
  just _openwrt-render "$OUT"

  if [ -z "$(find "$OUT" -type f)" ]; then
    echo "Nothing to apply"
    exit 0
  fi

  # dropbear has no sftp-server, stream a tarball instead of using scp
  tar -C "$OUT" -cf - . | ssh {{ openwrt_router }} \
    'rm -rf /tmp/openwrt-stage && mkdir -m 700 /tmp/openwrt-stage && tar -xf - -C /tmp/openwrt-stage'

  ssh {{ openwrt_router }} "sudo sh -s -- {{ TIMEOUT }}" <<'EOF'
  set -eu

  TIMEOUT="$1"
  STAGE=/tmp/openwrt-stage
  BACKUP=/tmp/openwrt-backup
  PIDFILE=/tmp/openwrt-watchdog.pid

  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Another apply is pending confirmation, aborting" >&2
    rm -rf "$STAGE"
    exit 1
  fi

  HAS_BIRD=0
  if [ -f "$STAGE/etc/bird.conf" ]; then
    HAS_BIRD=1
    if ! bird -p -c "$STAGE/etc/bird.conf"; then
      echo "bird.conf failed parse check, aborting" >&2
      rm -rf "$STAGE"
      exit 1
    fi
  fi

  # Backup every file about to be replaced, remember the new ones (BACKUP is root-only)
  rm -rf "$BACKUP"
  mkdir -m 700 "$BACKUP" "$BACKUP/files"
  touch "$BACKUP/new"
  cd "$STAGE"
  find . -type f | while read -r FILE; do
    FILE="${FILE#./}"
    if [ -e "/$FILE" ]; then
      mkdir -p "$BACKUP/files/$(dirname "$FILE")"
      cp -a "/$FILE" "$BACKUP/files/$FILE"
    else
      echo "/$FILE" >> "$BACKUP/new"
    fi
  done

  # Baseline for change detection: /var/run/config.md5 does not survive reboots
  reload_config

  # Existing files keep their owner/mode, new ones are root-only
  find . -type f | while read -r FILE; do
    FILE="${FILE#./}"
    if [ -e "/$FILE" ]; then
      cat "$FILE" > "/$FILE"
    else
      mkdir -p "/$(dirname "$FILE")"
      cp "$FILE" "/$FILE"
      chown root:root "/$FILE"
      chmod 600 "/$FILE"
    fi
  done
  cd /
  rm -rf "$STAGE"

  # Watchdog: restore backup unless confirmed in time
  (
    set +e
    trap '' HUP
    sleep "$TIMEOUT"
    if [ ! -f "$BACKUP/confirmed" ]; then
      cd "$BACKUP/files"
      find . -type f | while read -r FILE; do
        cat "$FILE" > "/${FILE#./}"
      done
      xargs rm -f < "$BACKUP/new"
      reload_config
      if [ "$HAS_BIRD" = 1 ]; then
        if [ -f /etc/bird.conf ]; then
          birdc configure
        else
          /etc/init.d/bird stop
        fi
      fi
      logger -t openwrt-apply "not confirmed within ${TIMEOUT}s, rolled back"
    fi
    rm -f "$PIDFILE"
  ) </dev/null >/dev/null 2>&1 &
  echo $! > "$PIDFILE"

  # Reload in background: a network restart may kill this SSH session
  (
    set +e
    trap '' HUP
    sleep 1
    reload_config
    if [ "$HAS_BIRD" = 1 ]; then
      if pidof bird >/dev/null; then
        # bird reverts by itself if not confirmed in time
        birdc configure timeout "$TIMEOUT"
      else
        /etc/init.d/bird restart
      fi
    fi
    logger -t openwrt-apply "applied, waiting for confirmation"
  ) </dev/null >/dev/null 2>&1 &
  EOF

  CONFIRM='set -e
  kill -0 "$(cat /tmp/openwrt-watchdog.pid)"
  ping -c1 -W2 1.1.1.1 >/dev/null
  birdc configure confirm >/dev/null 2>&1 || true
  touch /tmp/openwrt-backup/confirmed
  kill "$(cat /tmp/openwrt-watchdog.pid)"
  rm -f /tmp/openwrt-watchdog.pid'

  echo "Applied, waiting for services to settle..."
  sleep 15

  # Confirm over a fresh connection: proves the router is still reachable
  DEADLINE=$(( SECONDS + {{ TIMEOUT }} - 25 ))
  while (( SECONDS < DEADLINE )); do
    if printf '%s\n' "$CONFIRM" | ssh -o ConnectTimeout=5 -o BatchMode=yes {{ openwrt_router }} 'sudo sh -s'; then
      echo "Confirmed"
      exit 0
    fi
    sleep 5
  done

  echo "Could not confirm, router will roll back within ~25s" >&2
  exit 1
