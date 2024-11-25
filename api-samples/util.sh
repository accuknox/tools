#!/bin/bash

DIR=/tmp/$$

ak_api()
{
	apiverbosity=${API_VERBOSE:-0}
	[[ $apiverbosity -gt 0 ]] && echo "API: [$1]"
	unset apicmd
	unset json_string
	read -r -d '' apicmd << EOH
curl $CURLOPTS "$1" \
	  -H "authorization: Bearer $TOKEN" \
	  -H 'content-type: application/json' \
	  -H "x-tenant-id: $TENANT_ID"
EOH
	if [ "$data_raw" != "" ]; then
		apicmd="$apicmd --data-raw '$data_raw'"
	fi
	[[ $apiverbosity -gt 1 ]] && echo "$apicmd"
	json_string=`eval "$apicmd"`
	if ! jq -e . >/dev/null 2>&1 <<<"$json_string"; then
		echo "API call failed: [$json_string]"
		exit 1
	fi
	[[ $apiverbosity -gt 1 ]] && echo "$json_string"
	unset data_raw
}

ak_prereq()
{
	[[ "$DIR" != "" ]] && mkdir -p $DIR
	command -v jq >/dev/null 2>&1 || { echo >&2 "require 'jq' to be installed. Aborting."; exit 1; }
}

function ak_cleanup {
	[[ "$DIR" != "" ]] && rm -rf $DIR
}

trap ak_cleanup EXIT

