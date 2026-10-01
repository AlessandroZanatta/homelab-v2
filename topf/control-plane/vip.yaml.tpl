---
machine:
  network:
    interfaces:
      - deviceSelector:
          physical: true
        dhcp: true
        vip:
          ip: "{{ .Data.controlPlaneVIP }}"
