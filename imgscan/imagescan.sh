#!/bin/bash

SA_JSON="$(pwd)/service_account.json"
[[ "$SA_EMAIL" == "" ]] && echo "SA_EMAIL / ServiceAccount Email not provided" && exit 1
[[ "$AKURL" == "" ]] && echo "AKURL / Accuknox endpoint is not set" && exit 1
[[ "$TENANT" == "" ]] && echo "TENANT / Tenant id is not set" && exit 1
[[ "$LABEL" == "" ]] && echo "LABEL / Labels are not set" && exit 1
[[ "$TOKEN" == "" ]] && echo "TOKEN / Auth token is not set" && exit 1
[[ "$IMGSPEC" == "" ]] && echo "IMGSPEC token is not set" && exit 1
[[ ! -f "$SA_JSON" ]] && echo "$SA_JSON file not found" && exit 1

export GOOGLE_APPLICATION_CREDENTIALS=$SA_JSON

#REGISTRY=${REGISTRY:-us-east1-docker.pkg.dev/kube-airgapped/accuknox-onprem}

gcloud auth activate-service-account $SA_EMAIL --key-file=$SA_JSON

for img in `gcloud artifacts docker images list "$REGISTRY" --include-tags --format=json | jq -r '.[] | "\(.package):\(.tags[])"' 2>/dev/null`; do
	[[ ! $img =~ $IMGSPEC ]] && echo -en "\nskipping image [$img] ...\n" && continue
	echo -en "\nscanning $img ...\n"
	rm -f report.json 2>/dev/null
	trivy image $img --format json --timeout 3600s -o report.json > report.log  2>&1
	[[ ! -f "report.json" ]] && echo "image scanning failed $img" && continue
	curl -L -X POST "https://$AKURL/api/v1/artifact/?tenant_id=$TENANT&data_type=TR&label_id=$LABEL&save_to_s3=false" -H "Tenant-Id: $TENANT" -H "Authorization: Bearer $TOKEN" --form 'file=@"./report.json"'
done
