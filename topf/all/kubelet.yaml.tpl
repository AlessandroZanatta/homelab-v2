---
# Required by metric-server
#   ref: https://www.talos.dev/v1.9/kubernetes-guides/configuration/deploy-metrics-server/
apiVersion: v1alpha1
kind: KubeletConfig
extraArgs:
  rotate-server-certificates: "true" # required by metrics-server
config:
  maxPods: 256
  {{- with index .Node.Data "taints" }}
  # Taints are only honoured when the node first registers
  #   ref: https://github.com/siderolabs/talos/discussions/9895
  registerNode: true
  registerWithTaints: {{ toJson . }}
  {{- end }}
