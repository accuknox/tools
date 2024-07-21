#!/bin/bash

if [ "$1" == "install" ]; then
	curl -s https://raw.githubusercontent.com/accuknox/tools/main/install.sh | bash
	exit 0
fi

if [ "$1" == "uninstall" ]; then
	curl -s https://raw.githubusercontent.com/accuknox/tools/main/uninstall.sh | bash
	exit 0
fi

if [ "$1" == "getpolicies" ]; then
	curl -s https://raw.githubusercontent.com/accuknox/tools/main/get_discovered_yamls.sh | bash
	exit 0
fi

