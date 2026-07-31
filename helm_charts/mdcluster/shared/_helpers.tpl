{{- define "render.env" -}}
{{- range $key, $value := . }}
- name: {{ $key }}
  value: {{ $value | toString | quote }}
{{- end }}
{{- end }}

{{/*
Product name -- the single source of truth shared by both charts (via the
symlinked helper), so the config/secret names and labels can never drift.
*/}}
{{- define "mdcls.productName" -}}mdcluster{{- end -}}

{{- define "config-map-name" -}}
{{- printf "%s-config" (include "mdcls.productName" .) -}}
{{- end -}}

{{- define "secrets-map-name" -}}
{{- printf "%s-secrets" (include "mdcls.productName" .) -}}
{{- end -}}

{{/*
Build a fully-qualified image reference as <DOCKER_REPO>:<name>-<version>.
version defaults to MDCLS_VERSION when omitted/empty.
Usage: {{ include "mdcls.image" (dict "root" $ "name" $imageName "version" $ver) }}
*/}}
{{- define "mdcls.image" -}}
{{- $version := .version | default .root.Values.MDCLS_VERSION -}}
{{- printf "%s:%s-%s" .root.Values.DOCKER_REPO .name $version -}}
{{- end -}}

{{/*
Render startup/liveness/readiness probes. The exec command is fixed
(healthcheck.sh <phase>); only timeoutSeconds/failureThreshold/periodSeconds
are user-tunable via per-service overrides that merge over the baked-in defaults.
Usage: {{ include "mdcls.probes" (dict "defaults" $probeDefaults "overrides" $cfg.probes) }}
  defaults  - dict keyed by "startup"/"liveness"/"readiness"; only the phases
              present are rendered. Each value: dict of periodSeconds/
              timeoutSeconds/failureThreshold.
  overrides - the service's optional .probes map (same shape), merged per-phase.
*/}}
{{- define "mdcls.probes" -}}
{{- $overrides := .overrides | default dict -}}
{{- range $phase := (list "startup" "liveness" "readiness") -}}
{{- $def := index $.defaults $phase -}}
{{- if $def }}
{{- $ovr := index $overrides $phase | default dict -}}
{{- $p := merge (deepCopy $ovr) $def }}
{{ $phase }}Probe:
  exec:
    command: ["sh", "-c", "${WORK_DIR}/healthcheck.sh {{ $phase }}"]
  periodSeconds: {{ $p.periodSeconds }}
  {{- if not (kindIs "invalid" $p.timeoutSeconds) }}
  timeoutSeconds: {{ $p.timeoutSeconds }}
  {{- end }}
  failureThreshold: {{ $p.failureThreshold }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render optional pod scheduling knobs (nodeSelector/affinity/tolerations).
Usage: {{ include "mdcls.scheduling" $cfg | nindent 6 }}
*/}}
{{- define "mdcls.scheduling" -}}
{{- if .nodeSelector }}
nodeSelector:
  {{- toYaml .nodeSelector | nindent 2 }}
{{- end }}
{{- if .affinity }}
affinity:
  {{- toYaml .affinity | nindent 2 }}
{{- end }}
{{- if .tolerations }}
tolerations:
  {{- toYaml .tolerations | nindent 2 }}
{{- end }}
{{- end -}}