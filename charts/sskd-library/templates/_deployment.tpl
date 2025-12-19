{{/*
Standard Deployment template
Usage: {{ include "sskd-library.deployment" . }}
*/}}
{{- define "sskd-library.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.app.name }}-deployment
  namespace: {{ .Values.app.namespace | default "sskd" }}
  labels:
    app: {{ .Values.app.name }}
spec:
  replicas: {{ .Values.app.replicas | default 1 }}
  selector:
    matchLabels:
      app: {{ .Values.app.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.app.name }}
    spec:
      imagePullSecrets:
        - name: {{ .Values.app.name }}-ghcr-secret
      containers:
        - name: {{ .Values.app.name }}
          image: "{{ .Values.app.image.repository }}:{{ .Values.app.image.tag | default "latest" }}"
          imagePullPolicy: {{ .Values.app.image.pullPolicy | default "Always" }}
          ports:
            - containerPort: {{ .Values.app.port | default 80 }}
          {{- if .Values.app.env }}
          env:
            {{- range $key, $value := .Values.app.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
            {{- if .Values.app.secrets.apiUrl.enabled }}
            - name: {{ .Values.app.secrets.apiUrl.envName | default "API_URL" }}
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.app.name }}-api-url
                  key: api-url
            {{- end }}
          {{- end }}
          resources:
            requests:
              memory: {{ .Values.app.resources.requests.memory | default "128Mi" | quote }}
              cpu: {{ .Values.app.resources.requests.cpu | default "100m" | quote }}
            limits:
              memory: {{ .Values.app.resources.limits.memory | default "256Mi" | quote }}
              cpu: {{ .Values.app.resources.limits.cpu | default "200m" | quote }}
          livenessProbe:
            httpGet:
              path: {{ .Values.app.healthPath | default "/" }}
              port: {{ .Values.app.port | default 80 }}
            initialDelaySeconds: 10
            periodSeconds: 30
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: {{ .Values.app.healthPath | default "/" }}
              port: {{ .Values.app.port | default 80 }}
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
{{- end }}

