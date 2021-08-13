#!/usr/bin/env bash

. common.sh

check_prerequisites()
{
	command -v helm >/dev/null 2>&1 || { echo >&2 "Require helm but it's not installed.  Aborting."; exit 1; }
}

installMysql(){
    echo "Installing MySQL on $PLATFORM Kubernetes Cluster"
    helm install --wait mysql bitnami/mysql --version 8.6.1 \
		--namespace explorer \
		--set auth.user="test-user" \
		--set auth.password="password" \
		--set auth.rootPassword="password" \
		--set auth.database="accuknox"
}

installFeeder(){
    HELM_FEEDER="helm install feeder-service-cilium feeder --namespace=explorer --set image.repository=\"accuknox/test-feeder\" --set image.tag=\"latest\" "
    case $PLATFORM in
        gke)
            HELM_FEEDER="${HELM_FEEDER} --set platform=gke"
        ;;
        self-managed)
        ;;
        *)
            HELM_FEEDER="${HELM_FEEDER} --set kubearmor.enabled=false"
    esac
    eval "$HELM_FEEDER"
}

installCilium() {
    # FIXME this assumes that the project id, zone, and cluster name can't have
    # any underscores b/w them which might be a wrong assumption
	PROJECT_ID="$(echo "$CURRENT_CONTEXT_NAME" | awk -F '_' '{print $2}')"
	ZONE="$(echo "$CURRENT_CONTEXT_NAME" | awk -F '_' '{print $3}')"
	CLUSTER_NAME="$(echo "$CURRENT_CONTEXT_NAME" | awk -F '_' '{print $4}')"
    echo "Installing Cilium on $PLATFORM Kubernetes Cluster"
    case $PLATFORM in
        gke)
        	NATIVE_CIDR="$(gcloud container clusters describe "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID" --format 'value(clusterIpv4Cidr)')"
            helm install cilium cilium \
            --set image.repository=docker.io/accuknox/cilium-dev \
            --set image.tag=identity-soln \
            --set operator.image.repository=docker.io/accuknox/operator \
            --set operator.image.tag=identity-soln \
            --set operator.image.useDigest=false \
            --namespace kube-system \
            --set nodeinit.enabled=true \
            --set nodeinit.reconfigureKubelet=true \
            --set nodeinit.removeCbrBridge=true \
            --set cni.binPath=/home/kubernetes/bin \
            --set gke.enabled=true \
            --set ipam.mode=kubernetes  \
            --set hubble.relay.enabled=true \
            --set hubble.ui.enabled=true \
            --set nativeRoutingCIDR="$NATIVE_CIDR"\
            --set prometheus.enabled=true\
            --set operator.prometheus.enabled=true
        ;;

        *)
            helm install cilium cilium \
            --namespace kube-system \
            --set image.repository=docker.io/accuknox/cilium-dev \
            --set image.tag=identity-soln \
            --set operator.image.repository=docker.io/accuknox/operator \
            --set operator.image.tag=identity-soln \
            --set operator.image.useDigest=false \
            --set hubble.relay.enabled=true \
            --set prometheus.enabled=true \
            --set cgroup.autoMount.enabled=false \
            --set operator.prometheus.enabled=true
        ;;
    esac
}

check_prerequisites
echo "Adding helm repos"
helm repo add bitnami https://charts.bitnami.com/bitnami &> /dev/null
helm repo update

kubectl create ns explorer

autoDetectEnvironment

installCilium
handleLocalStorage apply
installMysql
installFeeder
handlePrometheusAndGrafana apply

if [[ $KUBEARMOR ]]; then
    echo "Installing KubeArmor"
    handleKubearmor apply
    handleKubearmorPrometheusClient apply
fi

handleKnoxAutoPolicy apply
handleSpire apply
