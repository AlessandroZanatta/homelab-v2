---
{{- with index .Node.Data "vpnEgressIP" }}
machine:
  network:
    interfaces:
      - deviceSelector:
          physical: true
        dhcp: true
        addresses:
          - {{ . }}/32
{{- end }}
