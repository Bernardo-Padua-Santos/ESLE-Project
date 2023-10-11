#!/bin/sh -vx
echo "running for" $1 "nodes and " $2 "threads"
export YSQL_NODES=$1 &&
java -jar ./yb-sample-apps.jar --workload SqlInserts --nodes $YSQL_NODES --num_unique_keys 500000 --num_threads_write $2 --num_threads_read 0 &&
echo "finished" 