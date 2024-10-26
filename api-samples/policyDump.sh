#!/bin/bash

CWPP_URL=https://cwpp.demo.accuknox.com
TENANT_ID=3730
TOKEN=" ------ Use AccuKnox Control Plane (Setting -> User-Management -> User (burger menu) -> Get-Access-Key) to create the token and paste it here ------"

# Other params
CURLOPTS="-s"
TMP=/tmp/$$
OUT="POLDUMP" # output directory where the policies will be dumped
clusterspec="gke.*" # regex for cluster name for whom to dump the policies

dump_policy_file()
{
	policy_id=$1
	curl $CURLOPTS "$CWPP_URL/policymanagement/v2/policy/$policy_id" \
	  -H "Authorization: Bearer $TOKEN" \
	  -H 'Content-Type: application/json' \
	  -H "X-Tenant-Id: $TENANT_ID" | jq -r .yaml > $polpath
	[[ $? -ne 0 ]] && echo "could not get policy with ID=[$policy_id]" && return
}

get_policy_list()
{
	polperpage=10
	for((pgprev=0;;pgprev+=$polperpage)); do
		pgnext=$(($pgprev + $polperpage))
		echo "fetching policies $pgprev to $pgnext ..."
		cnt=0
		while read pline; do
			((cnt++))
			arr=($pline)
			poldir=$cpath/${arr[2]}
			mkdir -p $poldir 2>/dev/null
			polpath=$poldir/${arr[1]}.yaml
			echo $polpath
			dump_policy_file ${arr[0]}
		done < <(curl $CURLOPTS "$CWPP_URL/policymanagement/v2/list-policy" \
		  -H "Authorization: Bearer $TOKEN" \
		  -H 'Content-Type: application/json' \
		  -H "X-Tenant-Id: $TENANT_ID" \
		  --data-raw "{\"workspace_id\":$TENANT_ID,\"workload\":\"k8s\",\"page_previous\":$pgprev,\"page_next\":$pgnext,\"filter\":{\"cluster_id\":[$1],\"namespace_id\":[],\"workload_id\":[],\"kind\":[],\"node_id\":[],\"pod_id\":[],\"type\":[],\"status\":[],\"tags\":[],\"name\":{\"regex\":[]},\"tldr\":{\"regex\":[]}}}" | jq -r '.list_of_policies[] | "\(.policy_id) \(.name) \(.namespace_name)"')
		[[ $cnt -lt $polperpage ]] && break
	done
}

get_cluster_id()
{
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		[[ ! $cname =~ $clusterspec ]] && echo "ignoring cluster [$cname] ..." && continue
		cpath=$OUT/$cname
		mkdir $cpath 2>/dev/null
		echo "fetching policies for cluster [$cname] ..."
		get_policy_list $cid
	done < <(curl $CURLOPTS "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID" \
	  -H 'accept: */*' \
	  -H "authorization: Bearer $TOKEN" \
	  -H 'content-type: application/json' \
	  -H "x-tenant-id: $TENANT_ID" | jq -r '.[] | "\(.ID) \(.ClusterName)"')
}

function cleanup {
	rm -rf $TMP 2>/dev/null
}
trap cleanup EXIT

init()
{
	mkdir -p $TMP 2>/dev/null
	mkdir -p $OUT 2>/dev/null
}

main()
{
	init
	get_cluster_id
}

# Processing starts here
main
