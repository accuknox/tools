#!/usr/bin/env bash

ns="knoxagents"

while getopts ":n:" opt; do
  case $opt in
    n)
      ns=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Specify namespace" >&2
      exit 1
      ;;
  esac
done

if [ -f "common.sh" ]; then
	. common.sh
else
	source <(curl -s https://raw.githubusercontent.com/accuknox/tools/main/common.sh)
fi

uninstallMysql() {
	kubectl get pod -n $ns -l "app.kubernetes.io/name=mysql" | grep "mysql" >/dev/null 2>&1
	[[ $? -ne 0 ]] && statusline AOK "no mysql found, skipping uninstall" && return 0
	statusline WAIT "uninstalling mysql"
	helm uninstall mysql --namespace $ns
	statusline AOK "uninstalling mysql"
}

uninstallFeeder() {
	helm uninstall feeder-service-cilium --namespace $ns
}

uninstallCilium() {
	kubectl get pod -A -l k8s-app=cilium | grep "cilium" >/dev/null 2>&1
	[[ $? -ne 0 ]] && statusline AOK "cilium not installed" && return 0
	statusline WAIT "uninstalling cilium"
	cilium uninstall -n $ns
	statusline AOK "uninstalled cilium"
}

uninstallSpire() {
	echo "uninstalling Spire"
	helm uninstall spire --namespace $ns
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

kubectl get ns $ns >/dev/null 2>&1
[[ $? -eq 0 ]] && kubectl delete ns $ns
