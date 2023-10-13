#!/bin/sh -vx
echo "running with" $1 "threads"
sysbench oltp_read_only --tables=5 --table-size=100000 --db-driver=pgsql --pgsql-host=yb-tserver-n1 --pgsql-port=5433 --pgsql-user=yugabyte --pgsql-db=yugabyte prepare &&
sysbench oltp_read_only --tables=5 --table-size=100000 --db-driver=pgsql --pgsql-host=yb-tserver-n1 --pgsql-port=5433 --pgsql-user=yugabyte --pgsql-db=yugabyte --threads=$1 --time=60 run &&
sysbench oltp_read_only --tables=5 --table-size=100000 --db-driver=pgsql --pgsql-host=yb-tserver-n1 --pgsql-port=5433 --pgsql-user=yugabyte --pgsql-db=yugabyte cleanup &&
echo "finished" 