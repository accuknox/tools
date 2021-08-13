#!/bin/bash

podname=$(kubectl get pod -n explorer -l container=knoxautopolicy -o=jsonpath='{.items[0].metadata.name}')
[[ $? -ne 0 ]] && echo "could not find knoxautopolicy pod" && exit 2
filelist=`kubectl exec -it -n explorer $podname -- ls -1 | grep "\.yaml"`

[[ "$filelist" == "" ]] && echo "No YAMLs found in pod=$podname" && exit 1

for f in `echo $filelist`; do
	f=$(echo $f | tr -d '\r')
	echo "copying $f from pod=$podname"
	kubectl cp explorer/$podname:$f $f
done
