#!/usr/bin/env bash

if [ -f "common.sh" ]; then
	. common.sh
else
	source <(curl -s https://raw.githubusercontent.com/accuknox/tools/main/common.sh)
fi

uninstallMysql() {
	kubectl get pod -n accuknox-agents -l "app.kubernetes.io/name=mysql" | grep "mysql" >/dev/null 2>&1
	[[ $? -ne 0 ]] && statusline AOK "no mysql found, skipping uninstall" && return 0
	statusline WAIT "uninstalling mysql"
	helm uninstall mysql --namespace accuknox-agents
	statusline AOK "uninstalling mysql"
}

uninstallFeeder() {
	helm uninstall feeder-service-cilium --namespace accuknox-agents
}

uninstallCilium() {
	kubectl get pod -A -l k8s-app=cilium | grep "cilium" >/dev/null 2>&1
	[[ $? -ne 0 ]] && statusline AOK "cilium not installed" && return 0
	statusline WAIT "uninstalling cilium"
	cilium uninstall
	statusline AOK "uninstalled cilium"
}

uninstallSpire() {
	echo "uninstalling Spire"
	helm uninstall spire --namespace accuknox-agents
}

autoDetectEnvironment

#handlePrometheusAndGrafana delete
handleKnoxAutoPolicy delete
#uninstallFeeder
uninstallMysql
handleLocalStorage delete
#uninstallSpire
uninstallCilium

#handleKubearmorPrometheusClient delete
handleKubearmor delete

kubectl get ns accuknox-agents >/dev/null 2>&1
[[ $? -eq 0 ]] && kubectl delete ns accuknox-agents
