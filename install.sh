#!/bin/sh

kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.10.1/examples/kubernetes/addons/prometheus/monitoring-example.yaml

./helmfile sync
