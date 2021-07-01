#!/bin/bash

HAS_HELM="$(type "helm" &> /dev/null && echo true || echo false)"
CURRENT_CONTEXT_NAME="$(kubectl config current-context view)"
PLATFORM="self-managed"

echo $CURRENT_CONTEXT_NAME

installMysql(){
    echo "Installing MySQL on $PLATFORM Kubernetes Cluster"
    helm install mysql bitnami/mysql --version 8.6.1 \
    --namespace explorer \
    --set auth.user="test-user" \
    --set auth.password="password" \
    --set auth.rootPassword="password" \
    --set auth.database="accuknox"
}

installKubearmorPrometheusClient(){
    echo "Installing Kubearmor Metrics Exporter on $PLATFORM Kubernetes Cluster"
    kubectl apply -f ./exporter/client_deploy.yaml
}

installLocalStorage(){
    echo "Installing Local Storage on $PLATFORM Kubernetes Cluster"
    case $PLATFORM in
        self-managed)
            kubectl apply -f ./local-path-provisioner/local-path-storage.yaml
        ;;
        *)
            echo "Skipping..."
    esac
}

installPrometheusAndGrafana(){
    # TODO: change the prometheus namespace
    # TODO: add Kubearmor dashboard
    echo "Installing prometheus and grafana on $PLATFORM Kubernetes Cluster"
    curl https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/kubernetes/addons/prometheus/monitoring-example.yaml |  sed 's/cilium-monitoring/explorer/' | kubectl apply -f -
}

installFeeder(){
  helm install feeder-service-cilium feeder \
    --namespace=explorer \
    --set image.repository="accuknox/test-feeder" \
    --set image.tag="latest" 
}

installCilium() {
    echo "Installing Cilium on $PLATFORM Kubernetes Cluster"
    case $PLATFORM in
        gke)
            NATIVE_CIDR="$(gcloud container clusters describe cluster-core-backend --zone us-central1-c --format 'value(clusterIpv4Cidr)')"
            helm install cilium cilium/cilium --version 1.9.6 \
            --namespace kube-system \
            --set nodeinit.enabled=true \
            --set nodeinit.reconfigureKubelet=true \
            --set nodeinit.removeCbrBridge=true \
            --set cni.binPath=/home/kubernetes/bin \
            --set gke.enabled=true \
            --set ipam.mode=kubernetes  \
            --set hubble.relay.enabled=true \
            --set hubble.ui.enabled=true \
            --set nativeRoutingCIDR=$NATIVE_CIDR\
            --set prometheus.enabled=true\
            --set operator.prometheus.enabled=true
        ;;
        
        *)
            helm install cilium cilium/cilium --version 1.9.6 \
            --namespace kube-system \
            --set hubble.relay.enabled=true \
            --set prometheus.enabled=true \
            --set operator.prometheus.enabled=true
        ;;
    esac
}

installKubearmor(){
    echo "Installing Kubearmor on $PLATFORM Kubernets Cluster"
    case $PLATFORM in
        gke)
            kubectl apply -f ./KubeArmor/GKE/kubearmor.yaml
        ;;
        microk8s)
            microk8s kubectl apply -f ./KubeArmor/microk8s/kubearmor.yaml
        ;;
        self-managed)
            kubectl apply -f ./KubeArmor/docker/kubearmor.yaml
        ;;
        containerd)
            kubectl apply -f ./KubeArmor/generic/kubearmor.yaml
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

installKnoxAutoPolicy(){
    echo "Installing KnoxAutoPolicy on on $PLATFORM Kubernetes Cluster"
    kubectl apply -f ./autoPolicy/service.yaml
    kubectl apply -f ./autoPolicy/dev-config.yaml
    kubectl apply -f ./autoPolicy/deployment.yaml
}

autoDetectEnvironment(){
    if [[ -z "$CURRENT_CONTEXT_NAME" ]]; then
        echo "no configuration has been provided"
        return $1
    fi
    
    echo "Autodetecting environment"
    if [[ $CURRENT_CONTEXT_NAME =~ ^minikube.* ]]; then
        PLATFORM="minikube"
        elif [[ $CURRENT_CONTEXT_NAME =~ ^gke_.* ]]; then
        PLATFORM="gke"
        elif [[ $CURRENT_CONTEXT_NAME =~ ^kind-.* ]]; then
        PLATFORM="kind"
    fi
}

installHelm(){
    cd /tmp/
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    cd -
}


if [[ $HAS_HELM != "true" ]]; then
    echo "Helm not found, installing helm"
    installHelm
fi

echo "Adding helm repos"
helm repo add cilium https://helm.cilium.io &> /dev/null
helm repo add bitnami https://charts.bitnami.com/bitnami &> /dev/null

kubectl create ns explorer &> /dev/null

autoDetectEnvironment

installLocalStorage
installMysql
installCilium
installKubearmor
installFeeder
installPrometheusAndGrafana
installKubearmorPrometheusClient
installKnoxAutoPolicy
