{{- define "render.env" -}}
{{- range $key, $value := . }}
- name: {{ $key }}
  value: {{ $value | toString | quote }}
{{- end }}
{{- end }}

{{/*
Product name -- the single source of truth for the config/secret names and
labels, so they can never drift between components.
*/}}
{{- define "mdcls.productName" -}}mdcluster{{- end -}}

{{- define "config-map-name" -}}
{{- printf "%s-config" (include "mdcls.productName" .) -}}
{{- end -}}

{{- define "secrets-map-name" -}}
{{- printf "%s-secrets" (include "mdcls.productName" .) -}}
{{- end -}}

{{/*
Generate an ADMIN_APIKEY that satisfies the access manager's validator: exactly
36 chars of [0-9a-f], at least 10 digits, at least 10 letters, and no run of 4+
of either class. A plain 36-char hex string only clears that ~3% of the time, so
build the key by alternating digit/letter -- 18 of each, longest run 1, always
valid.
*/}}
{{- define "mdcls.apikey" -}}
{{- $letters := list "a" "b" "c" "d" "e" "f" -}}
{{- $key := "" -}}
{{- range until 18 -}}
{{- $key = printf "%s%s%s" $key (randNumeric 1) (index $letters (mod (randNumeric 3 | int64) 6 | int)) -}}
{{- end -}}
{{- $key -}}
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

{{/*
Render a securityContext block from an already-merged dict (pod- or
container-level). Also guards runAsUser/runAsGroup: the images bake UID/GID 1000
with owner-only (0700) files, so the containers MUST run as 1000 — a different
value silently breaks at runtime (the non-root process cannot read the 0700
binaries/entrypoint or own its volumes). Rendering fails if either is set to
anything but 1000. To run as another UID, rebuild the images with build args
RUN_UID/RUN_GID set to that value, then override here.
*/}}
{{- define "mdcls.securityContext" -}}
{{- if and (hasKey . "runAsUser") (ne (int .runAsUser) 1000) -}}
{{- fail (printf "securityContext.runAsUser=%v is not supported — the images bake UID 1000 with owner-only (0700) files; rebuild the images with build arg RUN_UID to change it." .runAsUser) -}}
{{- end -}}
{{- if and (hasKey . "runAsGroup") (ne (int .runAsGroup) 1000) -}}
{{- fail (printf "securityContext.runAsGroup=%v is not supported — the images bake GID 1000; rebuild the images with build arg RUN_GID to change it." .runAsGroup) -}}
{{- end -}}
{{- with . }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Validate a component's optional tls block. There is no self-signed fallback:
when tls.enabled is true, secretName is REQUIRED -- rendering fails rather
than silently deploying without a certificate.
Usage: {{ include "mdcls.tlsValidate" (dict "name" "control-center" "tls" $tls) }}
*/}}
{{- define "mdcls.tlsValidate" -}}
{{- $name := .name -}}
{{- $tls := .tls -}}
{{- if and $tls.enabled (not $tls.secretName) -}}
{{- fail (printf "%s.tls: secretName is required when tls.enabled is true (no self-signed fallback)" $name) -}}
{{- end -}}
{{- end -}}

{{/*
Render the volumeMounts for a component whose tls block resolves to a real
Secret (see mdcls.tlsMounted below for the guard): a single volume named
"tls" (see mdcls.tlsVolumes), mounted twice via subPath -- once for the cert,
once for the key. The Secret is expected to be of type kubernetes.io/tls
(fixed data keys tls.crt/tls.key).
Usage: {{ include "mdcls.tlsVolumeMounts" (dict "mountBase" "/run/secrets/control-center") | nindent 12 }}
*/}}
{{- define "mdcls.tlsVolumeMounts" -}}
{{- $mountBase := .mountBase -}}
- name: tls
  mountPath: {{ printf "%s.crt" $mountBase }}
  subPath: tls.crt
  readOnly: true
- name: tls
  mountPath: {{ printf "%s.key" $mountBase }}
  subPath: tls.key
  readOnly: true
{{- end -}}

{{/*
Render the single tls Secret volume for a component whose tls block resolves
to a real Secret (see mdcls.tlsMounted below for the guard).
Usage: {{ include "mdcls.tlsVolumes" $tls | nindent 8 }}
*/}}
{{- define "mdcls.tlsVolumes" -}}
- name: tls
  secret:
    secretName: {{ .secretName | quote }}
{{- end -}}