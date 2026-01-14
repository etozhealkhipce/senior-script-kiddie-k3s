{{/*
Standard Service template
Usage: {{ include "sskd-library.service" . }}
*/}}
{{- define "sskd-library.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.app.name }}
  namespace: {{ .Values.app.namespace | default "sskd" }}
  labels:
    app: {{ .Values.app.name }}
spec:
  selector:
    app: {{ .Values.app.name }}
  ports:
    - port: {{ .Values.app.port | default 80 }}
      targetPort: {{ .Values.app.port | default 80 }}
{{- end }}

