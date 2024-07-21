#!/usr/bin/env bash

RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

statusline()
{
	status=$1
	shift
	[[ $status == AOK ]] || [[ $status == "0" ]] &&
		{
			printf "[${GREEN}OK${NC}] $*\n"
			return
		}
	[[ $status == WAIT ]] &&
		{
			printf "[${CYAN}..${NC}] $*\r"
			return
		}
	printf "[${RED}FAIL${NC}] $*\n"
	exit 1
}

autoDetectEnvironment(){
	CURRENT_CONTEXT_NAME="$(kubectl config current-context view)"
	[[ $? -ne 0 ]] && echo "kubectl failed. Do you have a k8s cluster configured?" && exit 1
	statusline AOK "Cluster name $CURRENT_CONTEXT_NAME"

	if [[ ! -z "$PLATFORM" ]]; then
		statusline AOK "User specified platform $PLATFORM"
		return
	fi

	PLATFORM="$CURRENT_CONTEXT_NAME"
	if [[ -z "$CURRENT_CONTEXT_NAME" ]]; then
		echo "no configuration has been provided"
		return
	fi

	statusline WAIT "Autodetecting environment"
	if [[ $CURRENT_CONTEXT_NAME =~ ^minikube.* ]]; then
		PLATFORM="minikube"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^gke_.* ]]; then
		PLATFORM="gke"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^eks-.* ]]; then
		PLATFORM="eks"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^arn:aws:eks.* ]]; then
		PLATFORM="eks"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^kind-.* ]]; then
		PLATFORM="kind"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^k3d-.* ]]; then
		PLATFORM="k3d"
	elif [[ $CURRENT_CONTEXT_NAME =~ ^kubernetes-.* ]]; then
		PLATFORM="self-managed"
	else
		echo "Failed to auto detect the platform."
		echo "Please proivde the name of the platform in the following format:"
		echo -e "\t PLATFORM={aks | eks | gke | k3d | kind | minikube | self-managed} $0"
		exit 1
	fi
	statusline AOK "detected platform $PLATFORM"
}

annotate()
{
	ns_ignore_list=("kube-system" "explorer" "cilium" "kubearmor")
	while read line; do
		depnm=${line/ */}
		depns=${line/* /}
		[[ " ${ns_ignore_list[*]} " =~ " ${depns} " ]] && continue
		echo "Applying KubeArmor visibility annotation for namespace=[$depns], $1=[$depnm]"
		kubectl annotate $1 -n $depns $depnm "kubearmor-visibility"="process,file,network" --overwrite
	done < <(kubectl get $1 -A -o=custom-columns=':metadata.name,:metadata.namespace' --no-headers)
}

applyKubearmorVisibility()
{
	annotate deployments.apps
	annotate pod
}

handleKubearmor(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	statusline WAIT "$1 kubearmor"
	if [ "$1" == "apply" ]; then
		karmor version | grep "kubearmor image (running)" >/dev/null
		if [ $? -eq 0 ]; then
			statusline AOK "skipping ... existing kubearmor installation found"
		else
			karmor install ${KA_INSTALL_OPTS}
			statusline $? "$1 kubearmor"
		fi
		# applyKubearmorVisibility	# This is not needed with latest kubearmor
		return 0
	fi
	karmor version | grep "kubearmor image (running)" >/dev/null
	[[ $? -ne 0 ]] && statusline AOK "skipping ... kubearmor installation not found" && return 0
	karmor uninstall
	statusline $? "$1 kubearmor"
	: << "END"
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
END
}

handleKnoxAutoPolicy()
{
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	kubectl get pod -l container=knoxautopolicy | grep "knoxautopolicy" >/dev/null 2>&1
	kap_install=$? #kap_install = 0 if installed already
	[[ "$1" == "apply" ]] && [[ $kap_install -eq 0 ]] && \
		statusline AOK "knoxautopolicy already installed" && return 0
	[[ "$1" == "delete" ]] && [[ $kap_install -ne 0 ]] && return 0
	KNOXAUTOPOLICY_REPO="https://raw.githubusercontent.com/accuknox/auto-policy-discovery/dev/deployments/k8s"
	KNOXAUTOPOLICY_DEP="$KNOXAUTOPOLICY_REPO/deployment.yaml --namespace explorer"

	statusline WAIT "$1 knoxautopolicy"
	kubectl $1 -f $KNOXAUTOPOLICY_DEP
	statusline AOK "$1 knoxautopolicy"
}

handlePrometheusAndGrafana(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 prometheus and grafana"
	kubectl $1 -f https://raw.githubusercontent.com/kubearmor/kubearmor-prometheus-exporter/main/deployments/prometheus/prometheus-grafana-deployment.yaml &> /dev/null
}

handleLocalStorage(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	statusline WAIT "$1 local storage"
	case $PLATFORM in
		self-managed)
			kubectl $1 -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
			kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class="true"
			;;
	esac
	statusline AOK "$1 local storage"
}

handleKubearmorPrometheusClient(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 Kubearmor Metrics Exporter"
	kubectl $1 -f https://raw.githubusercontent.com/kubearmor/kubearmor-prometheus-exporter/main/deployments/exporter-deployment.yaml
}

handleSpire(){
	[[ "$1" == "" ]] && echo "no operation specified, specify apply/delete" && return 1
	echo "$1 Spire"
	kubectl $1 -f ./spire/spire.yaml
}

