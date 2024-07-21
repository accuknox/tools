ns=${1:-default}

echo "Annotating GKE microservice demo pods in namespace $ns"

get_pod_name()
{
    POD_NAME=$(kubectl get pods -n $ns -l "$1" -o jsonpath='{.items[0].metadata.name}')
	[[ $? -ne 0 ]] && echo "unable to get pod name for label=\"$1\" ns=$ns" && exit 1
}

annotate_l7_vis()
{
	get_pod_name $1
	kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/$2/TCP/HTTP>"
}

annotate_l7_vis "app=checkoutservice" 5050
annotate_l7_vis "app=paymentservice" 50051
annotate_l7_vis "app=emailservice" 8080
annotate_l7_vis "app=productcatalogservice" 3550
annotate_l7_vis "app=shippingservice" 50051
annotate_l7_vis "app=cartservice" 7070
annotate_l7_vis "app=currencyservice" 7000
