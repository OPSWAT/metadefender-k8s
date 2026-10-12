{{/*
Expand the name of the chart.
*/}}
{{- define "mdss.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mdss.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "mdss.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mdss.labels" -}}
helm.sh/chart: {{ include "mdss.chart" . }}
{{ include "mdss.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mdss.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mdss.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mdss.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mdss.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Autoscaling mode of a component: "keda", "hpa" or "" (fixed size).
Call with (dict "component" $component "Values" $.Values).
merge treats false as unset, so a component's own hpa.enabled: false is resolved explicitly.
*/}}
{{- define "mdss.autoscaling" -}}
{{- $c := .component -}}
{{- $own := $c.hpa | default dict -}}
{{- $hpaEnabled := ternary $own.enabled .Values.hpa.enabled (hasKey $own "enabled") -}}
{{- if and .Values.keda.enabled (dig "keda" "queues" list $c) -}}
keda
{{- else if $hpaEnabled -}}
hpa
{{- end -}}
{{- end }}
