#!/usr/bin/env bash

. common.sh

uninstallMysql() {
	echo "Uninstalling MySQL on $PLATFORM Kubernetes Cluster"
	helm uninstall mysql \
		--namespace explorer
}

uninstallFeeder() {
	helm uninstall feeder-service-cilium \
		--namespace explorer

}

uninstallCilium() {
	echo "Uninstalling Cilium on $PLATFORM Kubernetes Cluster"
	helm uninstall cilium \
		--namespace kube-system

}

autoDetectEnvironment

handlePrometheusAndGrafana delete
handleKnoxAutoPolicy delete
uninstallFeeder
uninstallMysql
handleLocalStorage delete
handleSpire delete
uninstallCilium

if [[ $KUBEARMOR ]]; then
	handleKubearmorPrometheusClient delete
    handleKubearmor delete
fi

kubectl delete ns explorer
