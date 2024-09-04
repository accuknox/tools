#!/bin/bash
set -e

KSVER=v3.0.8
BASE_DIR=.ks
KSCACHE=.kscache
KUBESCAPE_EXEC=kubescape

command -v curl >/dev/null 2>&1 ||
	{
		echo "curl tool not found"
		exit 1
	}

command -v jq >/dev/null 2>&1 ||
	{
		echo "jq tool not found"
		exit 1
	}

[[ "$URL" == "" ]] && echo "URL env var not found" && exit 1
[[ "$TENANT_ID" == "" ]] && echo "TENANT_ID env var not found" && exit 1
[[ "$LABEL_NAME" == "" ]] && echo "LABEL_NAME env var not found" && exit 1
[[ "$AUTH_TOKEN" == "" ]] && echo "AUTH_TOKEN env var not found" && exit 1
[[ "$CLUSTER_NAME" == "" ]] && echo "CLUSTER_NAME env var not found" && exit 1
[[ "$CLUSTER_ID" == "" ]] && echo "CLUSTER_ID env var not found" && exit 1

mkdir -p $KSCACHE

# Function to determine OS and architecture
determine_os_and_arch() {
    osName=$(uname -s)
    case $osName in
        *MINGW*) osName=windows ;;
        Darwin*) osName=macos ;;
        *) osName=ubuntu ;;
    esac

    arch=$(uname -m)
    case $arch in
        *aarch64*|*arm64*) arch="-arm64" ;;
        *x86_64*) arch="" ;;
        *)
            echo -e "\033[33mArchitecture $arch may be unsupported, will try to install the amd64 one anyway."
            arch=""
            ;;
    esac
}

# Function to remove old installations
remove_old_install() {
    local exec_path=$1
    if [ -f "$exec_path" ]; then
        $SUDO rm -f "$exec_path" && echo -e "\033[32mRemoved old installation at $exec_path" || echo -e "\033[31mFailed to remove old installation at $exec_path"
    fi
}

# Parse command-line arguments
while getopts v: option; do
    case ${option} in
        v) RELEASE="download/${OPTARG}";;
        *) ;;
    esac
done

if [ "$KSVER" != "" ]; then
	[ -z "${RELEASE}" ] && RELEASE="download/$KSVER"
else
	[ -z "${RELEASE}" ] && RELEASE="latest/download"
fi

echo -e "\033[0;36mInstalling Kubescape..."

determine_os_and_arch

mkdir -p $BASE_DIR

OUTPUT=$BASE_DIR/$KUBESCAPE_EXEC
DOWNLOAD_URL="https://github.com/kubescape/kubescape/releases/${RELEASE}/kubescape${arch}-${osName}-latest"
echo "DOWNLOAD_URL=$DOWNLOAD_URL"

curl --progress-bar -L $DOWNLOAD_URL -o $OUTPUT

# Determine install directory
install_dir=/usr/local/bin
[ "$(id -u)" -ne 0 ] && install_dir=$BASE_DIR/bin && export PATH=$PATH:$BASE_DIR/bin

# Create install dir if it does not exist
mkdir -p $install_dir

chmod +x $OUTPUT

# Remove old installations
SUDO=""
[ "$(id -u)" -ne 0 ] && [ -n "$(which sudo)" ] && [ -f /usr/local/bin/$KUBESCAPE_EXEC ] && SUDO=sudo

remove_old_install "/usr/local/bin/$KUBESCAPE_EXEC"
remove_old_install "$BASE_DIR/bin/$KUBESCAPE_EXEC"

# Remove any old installations in user's PATH
IFS=':' read -ra ADDR <<< "$PATH"
for pdir in "${ADDR[@]}"; do
  if [ "$pdir/$KUBESCAPE_EXEC" != "$OUTPUT" ]; then
    remove_old_install "$pdir/$KUBESCAPE_EXEC"
  fi
done

# Move the new executable to the install directory
mv $OUTPUT $install_dir/$KUBESCAPE_EXEC

echo -e "\033[32mFinished Installation."

if [ "$(id -u)" -ne 0 ]; then
  echo -e "\033[1;35;32m\nRemember to add the Kubescape CLI to your path with:"
  echo -e "\033[1;35;40m$ export PATH=\$PATH:$BASE_DIR/bin"
fi

# Check cluster access by getting nodes
if ! kubectl get nodes &> /dev/null; then
    echo -e "\033[0;37;32m\nRun:"
    echo -e "\033[1;35;40m$ $KUBESCAPE_EXEC scan"
    echo
    exit 0
fi

echo -e "\033[0;37;40m"
echo -e "\033[0;37;32mExecuting Kubescape."
[[ "$CLUSTER_NAME" == "" ]] && echo "CLUSTER_NAME environment name is not provided" && exit 1
$KUBESCAPE_EXEC scan framework "allcontrols,clusterscan,mitre,nsa" --format json --cache-dir $KSCACHE --output $KSCACHE/report.json --cluster-name=${CLUSTER_NAME}

# get all controls
jq -s 'map(.controls[]) | unique_by(.controlID) | .[]' $KSCACHE/allcontrols.json \
  $KSCACHE/clusterscan.json \
  $KSCACHE/mitre.json $KSCACHE/nsa.json > $KSCACHE/controllist.json

export GENERATION_TIME=`date --utc -Isecond`

# augment result
jq ". +=
  {
	"generationTime": "'$ENV.GENERATION_TIME'",
	"summary": {
	  "controls": "'$controllist'"
	},
	"accuknox_metadata": {
	  "cluster_name": "'$ENV.CLUSTER_NAME'",
	  "cluster_id": "'$ENV.CLUSTER_ID'",
	  "label_name": "'$ENV.LABEL_NAME'"
	}
  }" $KSCACHE/report.json --slurpfile controllist $KSCACHE/controllist.json > $KSCACHE/report_tmp.json

mv $KSCACHE/report_tmp.json $KSCACHE/report.json

# push
curl --location --request POST \
	--header "Authorization: Bearer ${AUTH_TOKEN}" \
	--header "Tenant-Id: ${TENANT_ID}" \
	--form "file=@\"${KSCACHE}/report.json\"" \
	"https://${URL}/api/v1/artifact/?tenant_id=${TENANT_ID}&data_type=KS&save_to_s3=true&label_id=${LABEL_NAME}"
