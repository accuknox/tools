#!/bin/bash

podname=$(kubectl get pod -n explorer -l container=knoxautopolicy -o=jsonpath='{.items[0].metadata.name}')
[[ $? -ne 0 ]] && echo "could not find knoxautopolicy pod" && exit 2
echo "Downloading discovered policies from pod=$podname"

function trigger_policy_dump()
{
	kubectl exec -n explorer $podname -- ls /convert_$1_policy.sh 2>&1 >/dev/null
	[[ $? -eq 0 ]] && kubectl exec -n explorer $podname -- /convert_$1_policy.sh
}

function network_policy()
{
	trigger_policy_dump net
	filelist=`kubectl exec -n explorer $podname -- ls -1 | grep "cilium_policies.*\.yaml"`
	[[ "$filelist" == "" ]] && echo "No network policies discovered" && return
	for f in `echo $filelist`; do
		f=$(echo $f | tr -d '\r')
		typ=${f/_*/}
		ns=${f/*_policies_/}
		ns=${ns/.yaml/}
		kubectl cp explorer/$podname:$f $f
		cnt=`grep "kind:" $f | wc -l`
		echo "Got $cnt $typ policies in file $f"
	done
}

function system_policy()
{
	trigger_policy_dump sys
	filelist=`kubectl exec -n explorer $podname -- ls -1 | grep "kubearmor_policies.*\.yaml"`
	[[ "$filelist" == "" ]] && echo "No system policies discovered" && return 1
	for f in `echo $filelist`; do
		f=$(echo $f | tr -d '\r')
		typ=${f/_*/}
		kubectl cp explorer/$podname:$f $f
		cnt=`grep "kind:" $f | wc -l`
		echo "Got $cnt $typ policies in file $f"
	done
}

network_policy
system_policy
