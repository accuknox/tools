#!/usr/bin/env bash

. common.sh

uninstallMysql() {
	kubectl get pod -n explorer -l "app.kubernetes.io/name=mysql" | grep "mysql" >/dev/null 2>&1
	[[ $? -ne 0 ]] && statusline AOK "no mysql found, skipping uninstall" && return 0
	statusline WAIT "uninstalling mysql"
	helm uninstall mysql --namespace explorer
	statusline AOK "uninstalling mysql"
}

uninstallFeeder() {
	helm uninstall feeder-service-cilium --namespace explorer
}

uninstallCilium() {
	statusline WAIT "uninstalling cilium"
	helm uninstall cilium --namespace kube-system
	statusline AOK "uninstalled cilium"
}

uninstallSpire() {
	echo "uninstalling Spire"
	helm uninstall spire --namespace explorer
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

kubectl delete ns explorer
