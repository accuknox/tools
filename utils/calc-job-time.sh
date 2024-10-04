#!/bin/bash

ns=purestorage
SQLDB=${ns}_jobstats.db
PODF=/tmp/pod$$.log
TMP=/tmp/jobtime$$.log

get_data()
{
	echo "kubectl logs -n $ns $pod > $TMP"
	kubectl logs -n $ns $pod > $TMP
	[[ $? -ne 0 ]] && echo "failed getting logs from $ns/$pod" && return 1

	totsec=0
	partfail=0
	fullfail=0
	pass=0
	for asset in `grep "It took" $TMP | sed 's/.* for //g' | sed 's/ .*//g' | uniq`; do
		retry=`grep "It took .* $asset$" $TMP | wc -l`
		tsec=`grep "It took .* $asset$" $TMP | cut -f 3 -d ' ' | paste -s -d+ - | bc`
		tsec=`printf "%.0f" $tsec`
		sqlite3 $SQLDB "insert into stats (pod,asset,retry,time) \
					 values (\"$pod\",\"$asset\",$retry,$tsec);"
	done
}

cleanup()
{
	rm $PODF $TMP
}

main()
{
	rm $SQLDB
	sqlite3 $SQLDB "create table stats(pod text, asset text, retry int, time int);"
	cnt=0
	echo "getting pod details for namespace $ns"
	kubectl get pods -n $ns --sort-by .status.startTime | grep steampipe | cut -f 1 -d ' ' > $PODF
	totcnt=`wc -l $PODF | sed 's/ .*//g'`
	for pod in `cat $PODF`; do
		get_data
		((cnt++))
		echo "processed pod $cnt/$totcnt ..."
	done
	cleanup
}

# processing begins here...
main
