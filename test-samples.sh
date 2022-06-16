#!/bin/bash

for yaml in `ls -1 samples/*.yaml`; do
	exp_png=${yaml/.yaml/.png}
	echo "$yaml => $exp_png"
	./filter-policy -f $yaml -g /tmp/t.png
	diff /tmp/t.png $exp_png
	if [ $? -ne 0 ]; then
		echo "filter-policy graph output for $yaml is a mismatch"
		exit 1
	fi
done
exit 0
