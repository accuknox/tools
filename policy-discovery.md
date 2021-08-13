# Setup instructions for auto-policy-discovery

## 1. Clone explorer-charts
Explorer-charts is an Accuknox tool to setup the test environment with all relevant accuknox components in a test cluster.
```
git clone -b identity-solution git@github.com:accuknox/explorer-charts.git
cd explorer-charts
```

## 2. Setup k8s cluster (optional if you already have one)
```
minikube start --network-plugin=cni --memory=8192 --cpus=8
```
If you plan on using google microservices demo then you needs atleast 8 cpus and 8GB RAM.

## 3. Install components on k8s cluster
```
./install.sh
```
... this will take some time .. will install cilium/autopolicy/feeder-service/mysql/.. etc

## 4. Install your favourite demo app (optional)
Try following if you want to use [Online Boutique app aka Google Microservice Demo](https://github.com/GoogleCloudPlatform/microservices-demo):
```
kubectl apply -f other/google-uservice-demo-kubernetes-manifests-minikube.yaml
```
Note that the original google microservice demo manifest has been modified to work on minikube.

## 5. Get discovered policies
The policies will be auto-discovered inside knoxautopolicy pod. You may have to wait for policies to be discovered .. we trigger auto-discovery every 1000 flows received (with google microservice demo this would be less than a min)
```
./get_discovered_yamls.sh
```

Typical output:
```
❯ ./get_discovered_yamls.sh
Downloading discovered policies from pod=knoxautopolicy-74f5b5d65b-tv7v7
Got 9 cilium policies for namespace=explorer in file cilium_policies_explorer.yaml
Got 5 cilium policies for namespace=kube-system in file cilium_policies_kube-system.yaml
Got 2 cilium policies for namespace=spire in file cilium_policies_spire.yaml
Got 9 knox policies for namespace=explorer in file knox_policies_explorer.yaml
Got 5 knox policies for namespace=kube-system in file knox_policies_kube-system.yaml
Got 2 knox policies for namespace=spire in file knox_policies_spire.yaml
```
You can run this command as many times as you like. Every run it will get the latest discovered YAMLs.
At the end you will have YAMLs file with auto-discovered policies.

