#!/usr/bin/env bash

CURRENT_CONTEXT_NAME="$(kubectl config current-context view)"
PLATFORM="self-managed"

autoDetectEnvironment(){
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
	else
		echo "No k8s cluster configured or unknown env!"
		exit 2
	fi
}

handleKubearmor(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 Kubearmor on $PLATFORM Kubernets Cluster"
	case $PLATFORM in
		gke)
			kubectl $1 -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/GKE/kubearmor.yaml
			;;
		microk8s)
			microk8s kubectl $1 -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/microk8s/kubearmor.yaml
			;;
		self-managed)
			kubectl $1 -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/docker/kubearmor.yaml
			;;
		containerd)
			kubectl $1 -f https://raw.githubusercontent.com/kubearmor/KubeArmor/master/deployments/generic/kubearmor.yaml
			;;
		minikube)
			echo "Kubearmor cannot be installed on minikube. Skipping..."
			;;
		kind)
			echo "Kubearmor cannot be installed on kind. Skipping..."
			;;
		*)
			echo "Unrecognised platform: $PLATFORM"
	esac
}

handleKnoxAutoPolicy()
{
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	KNOXAUTOPOLICY_REPO="https://raw.githubusercontent.com/accuknox/knoxAutoPolicy-deployment/main/k8s"
	KNOXAUTOPOLICY_SVC="$KNOXAUTOPOLICY_REPO/service.yaml --namespace explorer"
	KNOXAUTOPOLICY_CFG="$KNOXAUTOPOLICY_REPO/dev-config.yaml --namespace explorer"
	KNOXAUTOPOLICY_DEP="$KNOXAUTOPOLICY_REPO/deployment.yaml --namespace explorer"
	KNOXAUTOPOLICY_SA="$KNOXAUTOPOLICY_REPO/serviceaccount.yaml --namespace explorer"

	echo "$1 KnoxAutoPolicy on on $PLATFORM Kubernetes Cluster"
	kubectl $1 -f $KNOXAUTOPOLICY_SVC
	kubectl $1 -f $KNOXAUTOPOLICY_CFG
	kubectl $1 -f $KNOXAUTOPOLICY_DEP
	kubectl $1 -f $KNOXAUTOPOLICY_SA
}

handlePrometheusAndGrafana(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 prometheus and grafana on $PLATFORM Kubernetes Cluster"
	kubectl $1 -f https://raw.githubusercontent.com/kubearmor/kubearmor-prometheus-exporter/main/deployments/prometheus/prometheus-grafana-deployment.yaml &> /dev/null
}

handleLocalStorage(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 Local Storage on $PLATFORM Kubernetes Cluster"
	case $PLATFORM in
		self-managed)
			kubectl $1 -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
			kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class="true"
			;;
		*)
			echo "Skipping..."
	esac
}

handleKubearmorPrometheusClient(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 Kubearmor Metrics Exporter on $PLATFORM Kubernetes Cluster"
	kubectl $1 -f https://raw.githubusercontent.com/kubearmor/kubearmor-prometheus-exporter/main/deployments/exporter-deployment.yaml
}

handleSpire(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 Spire on $PLATFORM Kubernetes Cluster"
	kubectl $1 -f ./spire/spire.yaml
}

