#!/usr/bin/env bash

CURRENT_CONTEXT_NAME="$(kubectl config current-context view)"
PLATFORM="self-managed"

uninstallMysql() {
	echo "Uninstalling MySQL on $PLATFORM Kubernetes Cluster"
	helm uninstall mysql \
		--namespace explorer
}

uninstallKubearmorPrometheusClient() {
	echo "Uninstalling Kubearmor Metrics Exporter on $PLATFORM Kubernetes Cluster"
	kubectl delete -f ./exporter/client_deploy.yaml
}

uninstallLocalStorage() {
	echo "Uninstalling Local Storage on $PLATFORM Kubernetes Cluster"
	case $PLATFORM in
	self-managed)
		kubectl delete -f ./local-path-provisioner/local-path-storage.yaml
		;;
	*)
		echo "Skipping..."
		;;
	esac
}

uninstallPrometheusAndGrafana() {
	echo "Uninstalling prometheus and grafana on $PLATFORM Kubernetes Cluster"
	kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/kubernetes/addons/prometheus/monitoring-example.yaml
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

uninstallKubearmor() {
	echo "Uninstalling Kubearmor on $PLATFORM Kubernets Cluster"
	case $PLATFORM in
	gke)
		kubectl delete -f ./KubeArmor/GKE/kubearmor.yaml
		;;
	microk8s)
		microk8s kubectl delete -f ./KubeArmor/microk8s/kubearmor.yaml
		;;
	self-managed)
		kubectl delete -f ./KubeArmor/docker/kubearmor.yaml
		;;
	containerd)
		kubectl delete -f ./KubeArmor/generic/kubearmor.yaml
		;;
	*)
		echo "Unrecognised platform: $PLATFORM"
		;;
	esac
}

uninstallKnoxAutoPolicy() {
	echo "Uninstalling KnoxAutoPolicy on on $PLATFORM Kubernetes Cluster"
	kubectl delete -f ./autoPolicy/service.yaml
	kubectl delete -f ./autoPolicy/dev-config.yaml
	kubectl delete -f ./autoPolicy/deployment.yaml
}

autoDetectEnvironment() {
	if [[ -z "$CURRENT_CONTEXT_NAME" ]]; then
		echo "no configuration has been provided"
		return
	fi

	echo "Autodetecting environment"
	if [[ $CURRENT_CONTEXT_NAME =~ ^minikube.* ]]; then
		PLATFORM="minikube"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^gke_.* ]]; then
		PLATFORM="gke"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^kind-.* ]]; then
		PLATFORM="kind"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^k3d-.* ]]; then
		PLATFORM="k3d"
	fi
}

autoDetectEnvironment

uninstallLocalStorage
uninstallMysql
uninstallCilium
uninstallKubearmor
uninstallFeeder
uninstallPrometheusAndGrafana
uninstallKubearmorPrometheusClient
uninstallKnoxAutoPolicy
