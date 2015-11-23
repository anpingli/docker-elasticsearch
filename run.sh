#!/bin/bash

set -x
set -e

if [ -z "$CLUSTER_NAME" ] ; then
    echo CLUSTER_NAME not set - using bitscout
    export CLUSTER_NAME=bitscout
fi
mkdir -p /elasticsearch/$CLUSTER_NAME
if [ -n "$USE_SEARCHGUARD" ] ; then
    ln -s /etc/elasticsearch/keys/searchguard.key /elasticsearch/$CLUSTER_NAME/searchguard_node_key.key
fi

# the amount of RAM allocated should be half of available instance RAM.
# ref. https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html#_give_half_your_memory_to_lucene
regex='^([[:digit:]]+)([GgMm])$'
if [[ "${INSTANCE_RAM}" =~ $regex ]]; then
	num=${BASH_REMATCH[1]}
	unit=${BASH_REMATCH[2]}
	if [[ $unit =~ [Gg] ]]; then
		((num = num * 1024)) # enables math to work out for odd gigs
	fi
	if [[ $num -lt 512 ]]; then
		echo "INSTANCE_RAM set to ${INSTANCE_RAM} but must be at least 512M"
		exit 1
	fi
	ES_JAVA_OPTS="${ES_JAVA_OPTS} -Xms256M -Xmx$(($num/2))m"
else
	echo "INSTANCE_RAM env var is invalid: ${INSTANCE_RAM}"
	exit 1
fi

add_index_template() {
    sleep 5
    curl -v -X PUT -d@/usr/share/elasticsearch/config/com.redhat.bitscout-template.json http://localhost:9200/_template/bitscout
}

add_index_template &

/usr/share/elasticsearch/bin/elasticsearch
