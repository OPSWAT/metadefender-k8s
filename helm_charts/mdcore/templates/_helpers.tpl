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
True when the md-core pod should run DB upgrade in an initContainer.
Requires UPGRADE_DB=true and remote/shared DB mode (MDCORE_DB_MODE=4).
*/}}
{{- define "mdss.upgradeDbInitContainerEnabled" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- and (eq $component.name "md-core") (eq ($root.Values.env.UPGRADE_DB | default "false" | toString) "true") (eq ($root.Values.MDCORE_DB_MODE | toString) "4") -}}
{{- end -}}

{{/*
Resolve the Kubernetes volume used for STORAGE_PATH credential handoff between
the upgrade initContainer and the md-core main container.
Returns a dict: name, mountPath, auto (chart renders emptyDir when true), subPath (optional).
*/}}
{{- define "mdss.mdCoreStoragePathVolume" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $storagePath := $root.Values.STORAGE_PATH | default "/metadefendercore" -}}
{{- if $component.persistentDir -}}
{{- $subPath := "" -}}
{{- if not (eq $root.Values.storage_provisioner "hostPath") -}}
{{- $subPath = $component.name -}}
{{- end -}}
{{- dict "name" $component.name "mountPath" $component.persistentDir "auto" false "subPath" $subPath | toYaml -}}
{{- else -}}
{{- $volName := "" -}}
{{- range $component.extraVolumeMounts | default list -}}
{{- if eq .mountPath $storagePath -}}
{{- $volName = .name -}}
{{- end -}}
{{- end -}}
{{- if $volName -}}
{{- dict "name" $volName "mountPath" $storagePath "auto" false "subPath" "" | toYaml -}}
{{- else -}}
{{- dict "name" "md-core-shared-storage" "mountPath" $storagePath "auto" true "subPath" "" | toYaml -}}
{{- end -}}
{{- end -}}
{{- end -}}
