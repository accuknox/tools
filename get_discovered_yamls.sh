#!/bin/bash

podname=$(kubectl get pod -n explorer -l container=knoxautopolicy -o=jsonpath='{.items[0].metadata.name}')
[[ $? -ne 0 ]] && echo "could not find knoxautopolicy pod" && exit 2
filelist=`kubectl exec -it -n explorer $podname -- ls -1 | grep ".*_policies_.*\.yaml"`

[[ "$filelist" == "" ]] && echo "No YAMLs found in pod=$podname" && exit 1

echo "Downloading discovered policies from pod=$podname"
for f in `echo $filelist`; do
	f=$(echo $f | tr -d '\r')
	typ=${f/_*/}
	ns=${f/*_policies_/}
	ns=${ns/.yaml/}
	cnt=`grep "kind:" $f | wc -l`
	echo "Got $cnt $typ policies for namespace=$ns in file $f"
	kubectl cp explorer/$podname:$f $f
done
