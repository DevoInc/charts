{{- define "devo-relay.autosetup.properties.tpl" -}}

relay.name = {{ .Values.autosetup.config.relayName | default "<AUTOSETUP_RELAY_NAME>"}}

cloud = {{ .Values.autosetup.config.cloud | default "MANUAL" }}

{{- if or (not .Values.autosetup.config.cloud) (eq .Values.autosetup.config.cloud "MANUAL") }}
elb.host = {{ .Values.autosetup.config.devoEventLoadBalancerHost }}
elb.port = {{ .Values.autosetup.config.devoEventLoadBalancerPort }}

relay.api.url = {{ .Values.autosetup.config.relayApiUri }}
search.api.url = {{ .Values.autosetup.config.queryApiUri }}
{{- end}}

api.key = {{ .Values.autosetup.config.apiKey }}
api.secret = {{ .Values.autosetup.config.apiSecret }}

{{- if .Values.autosetup.config.proxyHost }}
proxy.host = {{ .Values.autosetup.config.proxyHost }}
proxy.port = {{ .Values.autosetup.config.proxyPort }}
{{- if .Values.autosetup.config.proxyUsername }}
proxy.username = {{ .Values.autosetup.config.proxyUsername }}
{{- end }}
{{- if .Values.autosetup.config.proxyPassword }}
proxy.password = {{ .Values.autosetup.config.proxyPassword }}
{{- end }}
{{- end }}

{{- if .Values.autosetup.config.enableImpersonation }}
relay.impersonation.enabled = {{ .Values.autosetup.config.enableImpersonation }}
{{- end }}

{{- end }}