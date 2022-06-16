#!/bin/bash

TMPNG=/tmp/t.png

for yaml in `ls -1 samples/*.yaml`; do
	exp_png=${yaml/.yaml/.png}
	echo "$yaml => $exp_png"
	rm $TMPNG
	./filter-policy -f $yaml -g $TMPNG
	[[ ! -f $TMPNG ]] && echo "Output File not created!!"
	TSZ=`stat --printf="%s" $TMPNG`
	tolerance=`echo $(($TSZ * 5/100))`
	PNG=`stat --printf="%s" $exp_png`

	X=`echo $(($TSZ - $tolerance))`
	Y=`echo $(($TSZ + $tolerance))`

	if [ $PNG -gt $X ] && [ $PNG -lt $Y ]; then
		echo "PNGs are similar in size"
	else
		echo "too much variation in the generated png"
		exit 1
	fi
done
exit 0
