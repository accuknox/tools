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
	kubectl delete -f https://raw.githubusercontent.com/kubearmor/kubearmor-prometheus-exporter/main/deployments/exporter-deployment.yaml
}

uninstallLocalStorage() {
	echo "Uninstalling Local Storage on $PLATFORM Kubernetes Cluster"
	case $PLATFORM in
	self-managed)
		kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
		;;
	*)
		echo "Skipping..."
		;;
	esac
}

uninstallPrometheusAndGrafana() {
	echo "Uninstalling prometheus and grafana on $PLATFORM Kubernetes Cluster"
	kubectl delete -f https://raw.githubusercontent.com/kubearmor/kubearmor-prometheus-exporter/main/deployments/prometheus/prometheus-grafana-deployment.yaml &> /dev/null
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
		kubectl delete -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/GKE/kubearmor.yaml
		;;
	microk8s)
		microk8s kubectl delete -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/microk8s/kubearmor.yaml
		;;
	self-managed)
		kubectl delete -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/docker/kubearmor.yaml
		;;
	containerd)
		kubectl delete -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/generic/kubearmor.yaml

		;;
	*)
		echo "Unrecognised platform: $PLATFORM"
		;;
	esac
}

uninstallKnoxAutoPolicy() {
	kubectl delete -f https://raw.githubusercontent.com/accuknox/knoxAutoPolicy-deployment/main/k8s/service.yaml --namespace explorer
    kubectl delete -f ./autoPolicy/dev-config.yaml --namespace explorer
    kubectl delete -f https://raw.githubusercontent.com/accuknox/knoxAutoPolicy-deployment/main/k8s/deployment.yaml --namespace explorer
    kubectl delete -f https://raw.githubusercontent.com/accuknox/knoxAutoPolicy-deployment/main/k8s/serviceaccount.yaml --namespace explorer
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

kubectl delete ns explorer
