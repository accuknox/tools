#!/bin/bash

# To set .accuknox.cfg check https://github.com/accuknox/tools/tree/main/api-samples
. ${ACCUKNOX_CFG:-~/.accuknox.cfg}
. util.sh

# Other params
clusterspec=".*" # regex for cluster name for whom to dump the policies
TMP=$DIR/$(basename $0).$$
OUT="POLDUMP" # output directory where the policies will be dumped

dump_policy_file()
{
	ak_api "$CWPP_URL/policymanagement/v2/policy/$1"
	echo $json_string | jq -r .yaml > $polpath
	[[ $? -ne 0 ]] && echo "could not get policy with ID=[$1]" && return
}

get_policy_list()
{
	polperpage=10
	for((pgprev=0;;pgprev+=$polperpage)); do
		pgnext=$(($pgprev + $polperpage))
		echo "fetching policies $pgprev to $pgnext ..."
		cnt=0
		data_raw="{\"workspace_id\":$TENANT_ID,\"workload\":\"k8s\",\"page_previous\":$pgprev,\"page_next\":$pgnext,\"filter\":{\"cluster_id\":[$1],\"namespace_id\":[],\"workload_id\":[],\"kind\":[],\"node_id\":[],\"pod_id\":[],\"type\":[],\"status\":[],\"tags\":[],\"name\":{\"regex\":[]},\"tldr\":{\"regex\":[]}}}"
		ak_api "$CWPP_URL/policymanagement/v2/list-policy"
		while read pline; do
			((cnt++))
			arr=($pline)
			poldir=$cpath/${arr[2]}
			mkdir -p $poldir 2>/dev/null
			polpath=$poldir/${arr[1]}.yaml
			echo $polpath
			dump_policy_file ${arr[0]}
		done < <(echo $json_string | jq -r '.list_of_policies[] | "\(.policy_id) \(.name) \(.namespace_name)"')
		[[ $cnt -lt $polperpage ]] && break
	done
}

get_cluster_id()
{
	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		[[ ! $cname =~ $clusterspec ]] && echo "ignoring cluster [$cname] ..." && continue
		cpath=$OUT/$cname
		mkdir $cpath 2>/dev/null
		echo "fetching policies for cluster [$cname] ..."
		get_policy_list $cid
	done < <(echo $json_string | jq -r '.[] | "\(.ID) \(.ClusterName)"')
}

main()
{
	mkdir -p $OUT 2>/dev/null
	get_cluster_id
}

# Processing starts here
main
