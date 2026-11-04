{{/*
Exposure helpers. Names use the mdcore. prefix for this chart.
*/}}

{{- define "mdcore.exposure.mode" -}}
{{- $e := .Values.exposure | default dict -}}
{{- default "none" $e.mode -}}
{{- end -}}

{{/*
Comma-separated substituted hostnames (fromJson cannot unmarshal JSON arrays in this
chart's Helm/sprig combination, so callers use splitList ",").
*/}}
{{- define "mdcore.exposure.hostnamesCSV" -}}
{{- $root := . -}}
{{- $e := $root.Values.exposure | default dict -}}
{{- $defaults := $e.defaults | default dict -}}
{{- $hosts := list -}}
{{- if and $e.routes (gt (len $e.routes) 0) -}}
  {{- range $e.routes -}}
    {{- $rh := .hostnames | default list -}}
    {{- if eq (len $rh) 0 -}}
      {{- $rh = $defaults.hostnames | default list -}}
    {{- end -}}
    {{- range $h := $rh -}}
      {{- $hosts = append $hosts ($h | replace "<APP_NAMESPACE>" $root.Release.Namespace) -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- range $h := ($defaults.hostnames | default list) -}}
    {{- $hosts = append $hosts ($h | replace "<APP_NAMESPACE>" $root.Release.Namespace) -}}
  {{- end -}}
{{- end -}}
{{- $hosts | uniq | join "," -}}
{{- end -}}

{{- define "mdcore.exposure.gatewayIsDedicated" -}}
{{- $e := .Values.exposure | default dict -}}
{{- $g := $e.gateway | default dict -}}
{{- eq (default "dedicated" $g.mode) "dedicated" -}}
{{- end -}}

{{- define "mdcore.exposure.backendName" -}}
{{- $e := .Values.exposure | default dict -}}
{{- $d := $e.defaults | default dict -}}
{{- default "md-core" $d.service -}}
{{- end -}}

{{- define "mdcore.exposure.backendPort" -}}
{{- $e := .Values.exposure | default dict -}}
{{- $d := $e.defaults | default dict -}}
{{- default 8008 $d.port -}}
{{- end -}}

{{- define "mdcore.exposure.validate" -}}
{{- $mode := include "mdcore.exposure.mode" . -}}
{{- if not (has $mode (list "none" "ingress" "gateway" "route")) -}}
{{- fail (printf "exposure.mode=%s is not valid. Use one of: none (default, Service only), ingress, gateway, route." $mode) -}}
{{- end -}}
{{- if eq $mode "gateway" -}}
  {{- $e := .Values.exposure | default dict -}}
  {{- $g := $e.gateway | default dict -}}
  {{- if and (eq (default "dedicated" $g.mode) "shared") (not $g.gatewayName) -}}
{{- fail "exposure.mode=gateway with gateway.mode=shared requires exposure.gateway.gatewayName (existing Gateway). Set gatewayName, or use gateway.mode=dedicated." -}}
  {{- end -}}
  {{- if and (eq (default "dedicated" $g.mode) "dedicated") (not $g.className) -}}
{{- fail "exposure.mode=gateway with gateway.mode=dedicated requires exposure.gateway.className (GatewayClass, eg for Envoy Gateway)." -}}
  {{- end -}}
{{- end -}}
{{- if and (eq $mode "route") (not .Values.core_route) -}}
{{- fail "exposure.mode=route requires the core_route block (see mdcore-openshift.yml)." -}}
{{- end -}}
{{- end -}}
