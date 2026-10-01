---
{{- $labels := index .Node.Data "nodeLabels" }}
{{- $annotations := index .Node.Data "nodeAnnotations" }}
{{- if or $labels $annotations }}
apiVersion: v1alpha1
kind: KubeNodeConfig
{{- with $labels }}
labels: {{ toJson . }}
{{- end }}
{{- with $annotations }}
annotations: {{ toJson . }}
{{- end }}
{{- end }}
