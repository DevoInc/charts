{{/*
Expand the name of the chart.
*/}}
{{- define "devo-relay.name" -}}
{{- default .Chart.Name .Values.relay.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "devo-relay.fullname" -}}
{{- if .Values.relay.fullnameOverride }}
{{- .Values.relay.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.relay.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "devo-relay.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "devo-relay.labels" -}}
helm.sh/chart: {{ include "devo-relay.chart" . }}
{{ include "devo-relay.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "devo-relay.selectorLabels" -}}
app.kubernetes.io/name: {{ include "devo-relay.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "devo-relay.serviceAccountName" -}}
{{- if .Values.relay.serviceAccount.create }}
{{- default (include "devo-relay.fullname" .) .Values.relay.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.relay.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the headless service to create a network domain to be
able to call the pods in a statefulset by hostname instead of IP
*/}}
{{- define "devo-relay.serviceDomain" -}}
{{ include "devo-relay.fullname" . }}-svc-domain
{{- end }}
