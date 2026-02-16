{{/*
Standard Ingress template
Usage: {{ include "sskd-library.ingress" . }}
*/}}
{{- define "sskd-library.ingress" -}}
{{- if .Values.app.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.app.name }}-ingress
  namespace: {{ .Values.app.namespace | default "sskd" }}
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: ssl
spec:
  rules:
    - host: {{ .Values.app.ingress.host }}
      http:
        paths:
          {{- range .Values.app.ingress.extraPaths }}
          - path: {{ .path }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ .serviceName }}
                port:
                  number: {{ .servicePort }}
          {{- end }}
          - path: {{ .Values.app.ingress.path | default "/" }}
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.app.name }}
                port:
                  number: {{ .Values.app.port | default 80 }}
  tls:
    - secretName: {{ .Values.app.name }}-tls
      hosts:
        - {{ .Values.app.ingress.host }}
{{- end }}
{{- end }}
