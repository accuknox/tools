#!/bin/bash

# To set .accuknox.cfg check https://github.com/accuknox/tools/tree/main/api-samples
. ${ACCUKNOX_CFG:-~/.accuknox.cfg}

# Other params
TMP=/tmp/$$

get_ticket_details()
{
	curl $CURLOPTS "$CSPM_URL/api/v1/tickets/$1" \
	  -H 'accept: */*' \
	  -H "authorization: Bearer $TOKEN" \
	  -H 'content-type: application/json' | jq .
}

get_ticket_list()
{
	while read line; do
		echo $line
		get_ticket_details $line
	done < <(curl $CURLOPTS "$CSPM_URL/api/v1/tickets?page=1&page_size=20&status=Opened&created_before=2024-11-13&created_after=2024-11-05" \
	  -H 'accept: */*' \
	  -H "authorization: Bearer $TOKEN" \
	  -H 'content-type: application/json' | jq -r '.results[].id')
}


function cleanup {
	rm -f $TMP 2>/dev/null
}
trap cleanup EXIT

main()
{
	get_ticket_list
}

# Processing starts here
main
