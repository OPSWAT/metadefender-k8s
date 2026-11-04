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

{{/*
Pod template shared by the Deployment and the StatefulSet of a core component.
Called with (dict "root" $ "component" $component "vct" <bool>); vct=true means the persistentDir
is backed by a StatefulSet volumeClaimTemplate instead of a shared volume.
*/}}
{{- define "mdcore.podTemplate" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $vct := .vct }}
  template:
    metadata:
      labels:
        app: {{ $component.name | quote }}
        product: mdcore
        {{- if $component.extra_labels }}
          {{- toYaml $component.extra_labels | nindent 8 }}
        {{- end }}
    spec:
      {{- $upgradeDbInit := include "mdss.upgradeDbInitContainerEnabled" (dict "root" $root "component" $component) | trim }}
      {{- $storageVol := dict }}
      {{- if eq $upgradeDbInit "true" }}
      {{- $storageVol = include "mdss.mdCoreStoragePathVolume" (dict "root" $root "component" $component) | fromYaml }}
      {{- end }}
      {{- $autoStorageVolume := and (eq $upgradeDbInit "true") $storageVol.auto }}
      containers:
        - envFrom:
            - configMapRef:
                name: mdcore-env
            {{- if $root.Values.env }}
            - configMapRef:
                name: {{ printf "%s-config" $root.Release.Name }}
            {{- end }}
          {{ if $component.custom_repo -}}
          image: {{ printf "%s/%s:%s" $root.Values.core_docker_repo $component.image $root.Values.BRANCH | quote }}
          {{- else -}}
          image: {{ $component.image | quote }}
          {{- end }}
          imagePullPolicy: {{ $root.Values.imagePullPolicy }}
          {{- $injectIgnitionJSON := and $root.Values.IGNITION_JSON (eq $component.name "md-core") }}
          {{- if or $component.env $injectIgnitionJSON (eq $upgradeDbInit "true") }}
          env:
            {{- if $component.env }}
            {{- toYaml $component.env | nindent 12 }}
            {{- end }}
            {{- if $injectIgnitionJSON }}
            - name: IGNITION_JSON
              valueFrom:
                secretKeyRef:
                  name: mdcore-stack-configs
                  key: IGNITION_JSON
            {{- end }}
            {{- if eq $upgradeDbInit "true" }}
            - name: UPGRADE_DB_SKIP
              value: "true"
            {{- end }}
          {{- end }}
          name: {{ $component.name | quote }}
          {{- if $component.ports }}
          ports:
          {{- range $component.ports }}
            - containerPort: {{ .port }}
          {{- end }}
          {{- end }}
          {{- if $component.livenessProbe }}
          livenessProbe:
            {{- toYaml $component.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if $component.startupProbe }}
          startupProbe:
            {{- toYaml $component.startupProbe | nindent 12 }}
          {{- end }}
          {{- if $component.readinessProbe }}
          readinessProbe:
            {{- toYaml $component.readinessProbe | nindent 12 }}
          {{- end }}
          {{- if $component.command }}
          command: 
            {{- toYaml $component.command | nindent 12 }}
          {{- end }}
          {{- if $component.args }}
          args:
            {{- toYaml $component.args | nindent 12 }}
          {{- end }}
          {{- if $component.securityContext }}
          securityContext:
            {{- toYaml $component.securityContext | nindent 12 }}
          {{- end }}
          {{- $tls := default dict $component.tls }}
          {{- if (or $component.mountConfig $tls.enabled $component.persistentDir $component.extraVolumeMounts $autoStorageVolume)}}
          volumeMounts:
            {{- if $component.mountConfig }}
            - name: {{ $component.mountConfig.configName }}
              mountPath: {{ $component.mountConfig.mountPath }}
              subPath: {{ $component.mountConfig.subPath }}
            {{ end }}
            {{- if $tls.enabled }}
            - name: {{ $component.tls.certSecret }}
              mountPath: {{ $root.Values.MDCORE_CERT_PATH }}/mdcore.crt
              subPath: {{ $component.tls.certSecretSubPath }}
            - name: {{ $component.tls.certKeySecret }}
              mountPath: {{ $root.Values.MDCORE_CERT_PATH }}/mdcore.key
              subPath: {{ $component.tls.certKeySecretSubPath }}
            {{ end }}
            {{- if $component.persistentDir }}
            - name: {{ $component.name }}
              mountPath: {{ $component.persistentDir }}
              {{- if and (not $vct) (not (eq $root.Values.storage_provisioner "hostPath")) }}
              subPath: {{ $component.name }}
              {{- end }}
            {{ end }}
            {{- if $autoStorageVolume }}
            - name: {{ $storageVol.name }}
              mountPath: {{ $storageVol.mountPath }}
            {{- end }}
            {{- if $component.extraVolumeMounts }}
              {{- toYaml $component.extraVolumeMounts | nindent 12 }}
            {{- end }}
          {{- end }}
          {{- if $component.resources }}
          resources:
            {{- toYaml $component.resources | nindent 12 }}
          {{- end }}
          {{- if $component.sidecars }}
            {{- toYaml $component.sidecars | nindent 8 }}
          {{- end }}
      {{- if or $component.initContainers (eq $upgradeDbInit "true") }}
      initContainers:
        {{- if $component.initContainers }}
        {{- toYaml $component.initContainers | nindent 8 }}
        {{- end }}
        {{- if eq $upgradeDbInit "true" }}
        - name: upgrade-db
          {{ if $component.custom_repo -}}
          image: {{ printf "%s/%s:%s" $root.Values.core_docker_repo $component.image $root.Values.BRANCH | quote }}
          {{- else -}}
          image: {{ $component.image | quote }}
          {{- end }}
          imagePullPolicy: {{ $root.Values.imagePullPolicy }}
          envFrom:
            - configMapRef:
                name: mdcore-env
            {{- if $root.Values.env }}
            - configMapRef:
                name: {{ printf "%s-config" $root.Release.Name }}
            {{- end }}
          env:
            - name: MDCORE_RUN_MODE
              value: "upgrade-only"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: mdcore-postgres-cred
                  key: user
            - name: DB_PWD
              valueFrom:
                secretKeyRef:
                  name: mdcore-postgres-cred
                  key: password
            - name: APIKEY
              valueFrom:
                secretKeyRef:
                  name: mdcore-api-key
                  key: value
          {{- if $component.securityContext }}
          securityContext:
            {{- toYaml $component.securityContext | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: {{ $storageVol.name }}
              mountPath: {{ $storageVol.mountPath }}
              {{- if $storageVol.subPath }}
              subPath: {{ $storageVol.subPath }}
              {{- end }}
        {{- end }}
      {{- end }}
      restartPolicy: Always
      {{- if $root.Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml $root.Values.imagePullSecrets | nindent 8 }}
      {{- end }}
      {{- if $component.customPodDefinitions }}
        {{- toYaml $component.customPodDefinitions | nindent 6 }}
      {{- end }}
      {{- $sharedPersistentVolume := and $component.persistentDir (not $vct) }}
      {{- if (or $component.mountConfig $tls.enabled $sharedPersistentVolume $component.extraVolumes $autoStorageVolume )}}
      volumes:
        {{- if $component.mountConfig }}
        - name: {{ $component.mountConfig.configName }}
          configMap:
            name: {{ $component.mountConfig.configName }}
        {{ end }} 
        {{- if $tls.enabled }}
        - name: {{ $component.tls.certSecret }}
          secret:
            secretName: {{ $component.tls.certSecret }}
            defaultMode: 0755
        - name: {{ $component.tls.certKeySecret }}
          secret:
            secretName: {{ $component.tls.certKeySecret }}
            defaultMode: 0755
        {{ end }}
        {{- if $sharedPersistentVolume }}
        {{- if eq $root.Values.storage_provisioner "hostPath" }}
        - name: {{ $component.name }}
          hostPath:
            path: {{ printf "/%s/%s" ( $root.Values.hostPathPrefix | replace "<APP_NAMESPACE>" $root.Release.Namespace) $component.name }}
            type: DirectoryOrCreate
        {{ else }}
        - name: {{ $component.name }}
          persistentVolumeClaim:
            {{- if $component.storage_name }}
            claimName: {{ printf "%s" $component.storage_name }}
            {{ else }}
            claimName: {{ printf "%s" $root.Values.storage_name }}
            {{ end }}
        {{ end }}
        {{ end }}
        {{- if $autoStorageVolume }}
        - name: {{ $storageVol.name }}
          emptyDir: {}
        {{- end }}
        {{- if $component.extraVolumes -}}
          {{- range $volumeLabel, $volume := $component.extraVolumes }}
        -
            {{- toYaml $volume | nindent 10 }}
          {{- end }}
        {{- end }}
      {{- end }}
{{- end }}
