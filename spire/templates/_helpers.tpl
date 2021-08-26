{{/*
Expand the spire telemetry configuration.
*/}}
{{- define "spire.telemetry" -}}
{{- if .Values.telemetry.enabled }}
telemetry {
  Statsd = [
    { address = {{ .Values.telemetry.address | quote }} },
  ]
}
{{- end }}
{{- end }}
