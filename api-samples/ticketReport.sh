#!/bin/bash

# To set .accuknox.cfg check https://github.com/accuknox/tools/tree/main/api-samples
. ${ACCUKNOX_CFG:-~/.accuknox.cfg}
. util.sh

get_ticket_details()
{
	ak_api "$CSPM_URL/api/v1/tickets/$1"
	echo $json_string | jq .
}

get_ticket_list()
{
	ak_api "$CSPM_URL/api/v1/tickets?page=1&page_size=20&status=Opened&created_before=2024-11-13&created_after=2024-11-05"
	while read line; do
		echo $line
		get_ticket_details $line
	done < <(echo $json_string | jq -r '.results[].id')
}

main()
{
	get_ticket_list
}

# Processing starts here
main
