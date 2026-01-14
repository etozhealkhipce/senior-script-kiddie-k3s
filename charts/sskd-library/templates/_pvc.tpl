{{/*
PersistentVolumeClaim template
Usage: {{ include "sskd-library.pvc" . }}
*/}}
{{- define "sskd-library.pvc" -}}
{{- if .Values.app.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Values.app.name }}-pvc
  namespace: {{ .Values.app.namespace | default "sskd" }}
  labels:
    app: {{ .Values.app.name }}
spec:
  accessModes:
    - ReadWriteOnce
  {{- if .Values.app.persistence.storageClass }}
  storageClassName: {{ .Values.app.persistence.storageClass }}
  {{- end }}
  resources:
    requests:
      storage: {{ .Values.app.persistence.size | default "10Gi" }}
{{- end }}
{{- end }}

