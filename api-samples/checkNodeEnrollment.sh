#!/bin/bash

# To set .accuknox.cfg check https://github.com/accuknox/tools/tree/main/api-samples
. ${ACCUKNOX_CFG:-~/.accuknox.cfg}
. util.sh

# Other params
TMP=$DIR/$(basename $0)
clusterspec=".*" # regex for cluster names

get_node_list()
{
	data_raw="{\"workspace_id\":$TENANT_ID,\"cluster_id\":[$cid],\"from_time\":[],\"to_time\":[]}"
	ak_api "$CWPP_URL/cm/api/v1/cluster-management/nodes-in-cluster"
	echo $json_string | jq -r '.result[].NodeName' > $TMP
cat <<EOH
{
"Cluster": "$cname",
"NodeCount": "$(wc -l < $TMP)",
"NodeList": [
EOH
	firstline=1
	while read line; do
		[[ $firstline -eq 0 ]] && firstline=0 && echo -en ","
		echo "\"$line\""
		firstline=0
	done < <(cat $TMP | sort)
	echo "]}"
}

get_cluster_id()
{
	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		[[ ! $cname =~ $clusterspec ]] && echo "ignoring cluster [$cname] ..." && continue
		get_node_list
	done < <(echo $json_string | jq -r '.[] | "\(.ID) \(.ClusterName)"')
}

main()
{
	ak_prereq
	get_cluster_id
}

# Processing starts here
main
