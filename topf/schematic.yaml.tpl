---
{{- if index .Node.Data "rpi" }}
overlay:
  image: siderolabs/sbc-raspberrypi
  name: rpi_generic
{{- end }}
customization:
  extraKernelArgs:
    - talos.platform=metal
    # Disable selinux for now
    #  ref: https://docs.siderolabs.com/talos/v1.14/security/selinux
    - -selinux
    - selinux=0
{{- range index .Node.Data "extraKernelArgs" }}
    - {{ . }}
{{- end }}
  systemExtensions:
    officialExtensions:
{{- if not (index .Node.Data "rpi") }}
      - siderolabs/intel-ucode
{{- end }}
{{- if index .Node.Data "longhornNode" }}
      - siderolabs/iscsi-tools
      - siderolabs/util-linux-tools
{{- end }}
