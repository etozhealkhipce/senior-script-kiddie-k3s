{{/*
All-in-one template - renders deployment, service, ingress, and proxy
Usage: {{ include "sskd-library.all" . }}
*/}}
{{- define "sskd-library.all" -}}
{{ include "sskd-library.deployment" . }}
---
{{ include "sskd-library.service" . }}
{{- if .Values.app.ingress.enabled }}
---
{{ include "sskd-library.ingress" . }}
{{- end }}
{{- if .Values.app.proxy }}
{{ include "sskd-library.proxy" . }}
{{- end }}
{{- end }}
