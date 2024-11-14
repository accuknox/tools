#!/bin/bash

# To set .accuknox.cfg check https://github.com/accuknox/tools/tree/main/api-samples
. ${ACCUKNOX_CFG:-~/.accuknox.cfg}

# Other params
TMP=/tmp/$(basename $0).$$
clusterspec=".*" # regex for cluster names

get_node_list()
{
	curl $CURLOPTS "$CWPP_URL/cm/api/v1/cluster-management/nodes-in-cluster" \
				  -H "authorization: Bearer $TOKEN" \
				  -H 'content-type: application/json' \
				  -H "x-tenant-id: $TENANT_ID" \
				  --data-raw "{\"workspace_id\":$TENANT_ID,\"cluster_id\":[$cid],\"from_time\":[],\"to_time\":[]}" | jq -r '.result[].NodeName' > $TMP
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
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		[[ ! $cname =~ $clusterspec ]] && echo "ignoring cluster [$cname] ..." && continue
		get_node_list
	done < <(curl $CURLOPTS "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID" \
	  -H 'accept: */*' \
	  -H "authorization: Bearer $TOKEN" \
	  -H 'content-type: application/json' \
	  -H "x-tenant-id: $TENANT_ID" | jq -r '.[] | "\(.ID) \(.ClusterName)"')
}

function cleanup {
	rm -f $TMP
}
prereq()
{
	command -v jq >/dev/null 2>&1 || { echo >&2 "require 'jq' to be installed. Aborting."; exit 1; }
}

trap cleanup EXIT

main()
{
	prereq
	get_cluster_id | jq .
}

# Processing starts here
main
