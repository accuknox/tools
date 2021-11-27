#!/usr/bin/env bash

. common.sh

uninstallMysql() {
	statusline WAIT "uninstalling mysql"
	: <<END
	command -v mysql >/dev/null 2>&1
		if [ $? -eq 0 ]; then
		kubectl port-forward -n explorer svc/mysql --address 0.0.0.0 --address :: 33067:3306 &
		if [ $? -eq 0 ]; then
			sleep 2
			sqlfwd=$!
			if [ $sqlfwd -gt 0 ]; then
				sqlcmd="mysql -h 127.0.0.1 -P 33067 -uroot -ppassword -Daccuknox"
				$sqlcmd -e "delete from network_policy;"
				$sqlcmd -e "delete from network_log;"
				$sqlcmd -e "delete from system_policy;"
				$sqlcmd -e "delete from system_log;"
			fi
			echo "terminating port-forwarding $sqlfwd"
			kill -9 $sqlfwd
		fi
	fi
END
	helm uninstall mysql --namespace explorer
	statusline AOK "uninstalling mysql"
}

uninstallFeeder() {
	helm uninstall feeder-service-cilium --namespace explorer
}

uninstallCilium() {
	statusline WAIT "uninstalling cilium"
	helm uninstall cilium --namespace kube-system
	statusline AOK "uninstalled cilium"
}

uninstallSpire() {
	echo "uninstalling Spire"
	helm uninstall spire --namespace explorer
}

autoDetectEnvironment

#handlePrometheusAndGrafana delete
handleKnoxAutoPolicy delete
#uninstallFeeder
uninstallMysql
handleLocalStorage delete
#uninstallSpire
uninstallCilium

#handleKubearmorPrometheusClient delete
handleKubearmor delete

kubectl delete ns explorer
