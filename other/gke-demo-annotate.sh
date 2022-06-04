ns=demo

get_pod_name()
{
    POD_NAME=$(kubectl get pods -n $ns -l "$1" -o jsonpath='{.items[0].metadata.name}')
}

get_pod_name "app=checkoutservice"
kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/5050/TCP/HTTP>"

get_pod_name "app=paymentservice"
kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/50051/TCP/HTTP>"

get_pod_name "app=emailservice"
kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/8080/TCP/HTTP>"

get_pod_name "app=productcatalogservice"
kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/3550/TCP/HTTP>"

get_pod_name "app=shippingservice"
kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/50051/TCP/HTTP>"

get_pod_name "app=cartservice"
kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/7070/TCP/HTTP>"

get_pod_name "app=currencyservice"
kubectl annotate pod $POD_NAME -n $ns io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Ingress/7000/TCP/HTTP>"
