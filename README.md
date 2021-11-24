# Explorer
Explorer allows the user to install multiple policy engines (KubeArmor, KubeArmor-Cilium) and makes it easy to deploy services like policy-discovery.

## Generate Network policies

Knoxautopolicy can generate network policies on the basis of the cilium telemetery data. Knoxautopolicy reads from a mysql DB, in which all the telemetery data has been stored. The data was stored by the feeder service. 

In order to generate network policies, we must first start the `net_worker`.
We'll first forward the port 9089 in order to connect to the auto policy service using `grpcurl`
```bash
kubectl port-forward -n explorer svc/knoxautopolicy --address 0.0.0.0 --address :: 9089:9089
```

In a separate terminal run
```bash
export DATA='{"policytype": "network"}'
grpcurl -plaintext -d "$DATA" localhost:9089 v1.worker.Worker.Start
```

The network policies will be generated inside the `network_policies` table in mysql.


## Generate Kubearmor Alerts
Kubearmor generates alerts when it's policy is violated. This generates some metrics this metrics are served by the prometheus metrics server, which is scraped by Prometheus, and displayed on our Grafana dashboard.

To generate the metrics we must deploy an example workload, of a few ubuntu pods.
```bash
kubectl apply -f https://raw.githubusercontent.com/accuknox/KubeArmor/master/examples/multiubuntu/multiubuntu-deployment.yaml
```

![multiubuntu](https://github.com/accuknox/KubeArmor/raw/master/.gitbook/assets/multiubuntu.png)

We can now apply some policies on this workload. For example:
### Block a process execution

In this following policy we block the sleep command in the namespace `multiubuntu` and to the pods with matchLabel `group-1`.
```yaml
apiVersion: security.accuknox.com/v1
kind: KubeArmorPolicy
metadata:
  name: ksp-group-1-proc-path-block
  namespace: multiubuntu
spec:
  severity: 5
  message: "block the sleep command"
  selector:
    matchLabels:
      group: group-1
  process:
    matchPaths:
    - path: /bin/sleep # try sleep 1 (permission denied)
      # fromSource:
      #   path: /bin/bash
  action:
    Block
```
Apply the policy:
```bash
# Apply the policy to group 1

kubectl apply -f https://raw.githubusercontent.com/accuknox/KubeArmor/master/examples/multiubuntu/security-policies/ksp-group-1-proc-path-block.yaml

kubectl exec -it -n multiubuntu {pod name for ubuntu-1} -- bash

# Kubearmor has successfully blocked the execution of the specified binary!
mutiubuntu$ sleep 1
(Permission Denied)

```

## Access Grafana

```bash
kubectl -n explorer port-forward service/grafana --address 0.0.0.0 --address :: 3000:3000
```

## Access Prometheus
```bash
kubectl -n explorer port-forward service/prometheus --address 0.0.0.0 --address :: 9090:9090
```



## Installation
The installation script deploys:
- Cilium
- SQL Database
- Kubearmor*
- Feeder service
- KnoxAutoPolicy
- Dynamic Storage Provisioner*
- Kubearmor Prometheus Metrics Exporter
- Prometheus and Grafana

```bash
./install.sh
```
## Uninstalation
```
./uninstall.sh
```
