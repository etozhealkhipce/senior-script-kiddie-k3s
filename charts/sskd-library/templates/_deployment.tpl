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
  {{- if .Values.app.updateStrategy }}
  strategy:
    {{- toYaml .Values.app.updateStrategy | nindent 4 }}
  {{- else if .Values.app.hostNetwork }}
  strategy:
    type: Recreate
  {{- end }}
  selector:
    matchLabels:
      app: {{ .Values.app.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.app.name }}
    spec:
      {{- if .Values.app.hostNetwork }}
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      {{- end }}
      {{- if .Values.app.nodeSelector }}
      nodeSelector:
        {{- toYaml .Values.app.nodeSelector | nindent 8 }}
      {{- end }}
      {{- if hasKey .Values.app "imagePullSecrets" }}
        {{- if .Values.app.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml .Values.app.imagePullSecrets | nindent 8 }}
        {{- end }}
      {{- else }}
      imagePullSecrets:
        - name: {{ .Values.app.name }}-ghcr-secret
      {{- end }}
      {{- if .Values.app.initContainers }}
      initContainers:
        {{- range .Values.app.initContainers }}
        - name: {{ .name }}
          image: {{ .image | default (printf "%s:%s" $.Values.app.image.repository ($.Values.app.image.tag | default "latest")) }}
          {{- if .command }}
          command: {{ .command | toJson }}
          {{- end }}
          {{- if .args }}
          args: {{ .args | toJson }}
          {{- end }}
          envFrom:
            - secretRef:
                name: {{ $.Values.app.name }}-secrets
                optional: true
          {{- if .env }}
          env:
            {{- range $key, $value := .env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
      containers:
        - name: {{ .Values.app.name }}
          image: "{{ .Values.app.image.repository }}:{{ .Values.app.image.tag | default "latest" }}"
          imagePullPolicy: {{ .Values.app.image.pullPolicy | default "Always" }}
          ports:
            - containerPort: {{ .Values.app.port | default 80 }}
          envFrom:
            - secretRef:
                name: {{ .Values.app.name }}-secrets
                optional: true
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
          {{- if hasKey .Values.app "livenessProbe" }}
            {{- if .Values.app.livenessProbe }}
          livenessProbe:
            {{- toYaml .Values.app.livenessProbe | nindent 12 }}
            {{- end }}
          {{- else }}
          livenessProbe:
            httpGet:
              path: {{ .Values.app.healthPath | default "/" }}
              port: {{ .Values.app.port | default 80 }}
            initialDelaySeconds: 30
            periodSeconds: 30
            timeoutSeconds: 15
            failureThreshold: 5
          {{- end }}
          {{- if hasKey .Values.app "readinessProbe" }}
            {{- if .Values.app.readinessProbe }}
          readinessProbe:
            {{- toYaml .Values.app.readinessProbe | nindent 12 }}
            {{- end }}
          {{- else }}
          readinessProbe:
            httpGet:
              path: {{ .Values.app.healthPath | default "/" }}
              port: {{ .Values.app.port | default 80 }}
            initialDelaySeconds: 10
            periodSeconds: 15
            timeoutSeconds: 10
            failureThreshold: 5
          {{- end }}
          {{- if and .Values.app.persistence .Values.app.persistence.enabled }}
          volumeMounts:
            - name: {{ .Values.app.name }}-data
              mountPath: {{ .Values.app.persistence.mountPath | default "/var/lib/postgresql/data" }}
          {{- end }}
      {{- if and .Values.app.persistence .Values.app.persistence.enabled }}
      volumes:
        - name: {{ .Values.app.name }}-data
          persistentVolumeClaim:
            claimName: {{ .Values.app.name }}-pvc
      {{- end }}
{{- end }}

