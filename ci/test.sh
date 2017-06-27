#!/bin/bash -ex

for i in $(seq 10); do
	curl -o /dev/null -fs -X OPTIONS http://possum > /dev/null && break || exit 1
	echo -n "."
	sleep 2
done

bundle exec ${@-rake jenkins} || true
