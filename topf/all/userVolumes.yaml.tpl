{{- range index .Node.Data "userVolumes" }}
---
apiVersion: v1alpha1
kind: UserVolumeConfig
name: {{ .name }}
provisioning: {{ toJson .provisioning }}
{{- end }}
