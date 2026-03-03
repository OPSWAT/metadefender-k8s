{{/*
Expand the name of the chart.
*/}}
{{- define "mdcluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mdcluster.fullname" -}}
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
{{- define "mdcluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mdcluster.labels" -}}
helm.sh/chart: {{ include "mdcluster.chart" . }}
{{ include "mdcluster.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mdcluster.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mdcluster.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mdcluster.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mdcluster.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL configuration with global fallback
*/}}
{{- define "mdcluster.postgresql.host" -}}
{{- if and .Values.global .Values.global.postgresql .Values.global.postgresql.host -}}
{{- .Values.global.postgresql.host -}}
{{- else -}}
{{- .Values.env.postgresql_host -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.postgresql.port" -}}
{{- if and .Values.global .Values.global.postgresql .Values.global.postgresql.port -}}
{{- .Values.global.postgresql.port -}}
{{- else -}}
{{- .Values.env.postgresql_port -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.postgresql.user" -}}
{{- if and .Values.global .Values.global.postgresql .Values.global.postgresql.user -}}
{{- .Values.global.postgresql.user -}}
{{- else -}}
{{- .Values.env.postgresql_user -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.postgresql.password" -}}
{{- if and .Values.global .Values.global.postgresql .Values.global.postgresql.password -}}
{{- .Values.global.postgresql.password -}}
{{- else -}}
{{- .Values.env.postgresql_password -}}
{{- end -}}
{{- end -}}

{{/*
RabbitMQ configuration with global fallback
*/}}
{{- define "mdcluster.rabbitmq.host" -}}
{{- if and .Values.global .Values.global.rabbitmq .Values.global.rabbitmq.host -}}
{{- .Values.global.rabbitmq.host -}}
{{- else -}}
{{- .Values.env.rabbitmq_host -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.rabbitmq.port" -}}
{{- if and .Values.global .Values.global.rabbitmq .Values.global.rabbitmq.port -}}
{{- .Values.global.rabbitmq.port -}}
{{- else -}}
{{- .Values.env.rabbitmq_port -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.rabbitmq.user" -}}
{{- if and .Values.global .Values.global.rabbitmq .Values.global.rabbitmq.user -}}
{{- .Values.global.rabbitmq.user -}}
{{- else -}}
{{- .Values.env.rabbitmq_user -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.rabbitmq.password" -}}
{{- if and .Values.global .Values.global.rabbitmq .Values.global.rabbitmq.password -}}
{{- .Values.global.rabbitmq.password -}}
{{- else -}}
{{- .Values.env.rabbitmq_password -}}
{{- end -}}
{{- end -}}

{{/*
Redis configuration with global fallback
*/}}
{{- define "mdcluster.redis.host" -}}
{{- if and .Values.global .Values.global.redis .Values.global.redis.host -}}
{{- .Values.global.redis.host -}}
{{- else -}}
{{- .Values.env.redis_host -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.redis.port" -}}
{{- if and .Values.global .Values.global.redis .Values.global.redis.port -}}
{{- .Values.global.redis.port -}}
{{- else -}}
{{- .Values.env.redis_port -}}
{{- end -}}
{{- end -}}

{{- define "mdcluster.redis.user" -}}
{{- $user := "" -}}
{{- if and .Values.global .Values.global.redis .Values.global.redis.user -}}
{{- $user = .Values.global.redis.user -}}
{{- else if .Values.env.redis_user -}}
{{- $user = .Values.env.redis_user -}}
{{- end -}}
{{- $user -}}
{{- end -}}

{{- define "mdcluster.redis.password" -}}
{{- $password := "" -}}
{{- if and .Values.global .Values.global.redis .Values.global.redis.password -}}
{{- $password = .Values.global.redis.password -}}
{{- else if .Values.env.redis_password -}}
{{- $password = .Values.env.redis_password -}}
{{- end -}}
{{- $password -}}
{{- end -}}
