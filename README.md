# ESLE-Project

## Repository structure

 1. USL_calculus: contains app for running linear regression to use its results for Universal Scalability Law analysis and a csv file with some observations. 
 2. scalability_benchmark: contains workload generator that runs the benchmark.
 3. ESLE-1stStage-Report.pdf
 4. ESLE-2ndStage-Report.pdf
 5. plots.xlsx: excel file containing benchmark measurements and plots.
 6. README.md: repository description and "how to run" instruction. 

## How to run a simple 3 node cluster with replication factor of 3 with Google Cloud VM instances

Firstly create 3 VM instances on Google Cloud (we will call them instance1, instance2 and instance3 for examples and better understanding purposes).

After starting and connecting to the instances via SSH, manually deploy YugabyteDB in each instance with the following steps:

1. As Python is a prerequisite, run this command to install or associate python with python3

```
sudo apt install python-is-python3
```

2. Download YugabyteDB
```
wget https://downloads.yugabyte.com/releases/2.18.4.0/yugabyte-2.18.4.0-b52-linux-x86_64.tar.gz
```

3. Extract the package

```
tar xvfz yugabyte-2.18.4.0-b52-linux-x86_64.tar.gz && cd yugabyte-2.18.4.0/
```

4. Configure YugabyteDB

```
./bin/post_install.sh
```

Now that the installation has suceeded, create the yugabyted cluster with the following steps (yugabyted is a directory inside the directory downloaded before):

1. In instance1 start the cluster

```
./bin/yugabyted start 
```

2. In instance2 and instance3 join instance1

```
./bin/yugabyted start --join <internal ip of instance1>
```

3. In each instance verify that the cluster status has been updated

```
./bin/yugabyted status
```

Notes:

1. The instance's internal ip can be easily observed in Google Cloud in VM Compute Engine > VM instances

2. In real world, replication factor is normally used as 3, so yugabyteDB automatically sets replication factor as 3 when the instance3 joins the cluster

3. Replication factor and additional configuration settings can be changed, for more information check https://docs.yugabyte.com/preview/reference/configuration/yugabyted/ in configure section
```
./bin/yugabyted configure data_placement <option>
```

## Running a scalability benchmark

Create and start a new VM instance (instance4).

First, install java 8 in instance4 
```
sudo apt update
sudo apt install default-jre
```
Then download the workload generator: 
```
wget https://github.com/yugabyte/yb-sample-apps/releases/download/v1.4.1/yb-sample-apps.jar -O yb-sample-apps.jar
```
After downloading the workload generator, set up an environment variable with the list of comma-separated *host:port* entries of instance1, instance2 and instance3
```
export YSQL_NODES=<instance1-internal-ip-addr>:5433,<instance2-internal-ip-addr>:5433,<instance3-internal-ip-addr>:5433
```

The, run a simple Insert (write operation) benchmark

```
java -jar ~/yb-sample-apps.jar    \
                   --workload SqlInserts        \
                   --nodes $YSQL_NODES          \
                   --num_unique_keys 5000000000 \
                   --num_threads_write 400      \
                   --num_threads_read 0         \
                   --uuid 00000000-0000-0000-0000-000000000001

```

The output will look like this:

```
0 [main] INFO com.yugabyte.sample.Main  - Starting sample app...
33 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Using a randomly generated UUID : 286f391c-d7d0-4ebe-9c68-1494e95962cf
39 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - App: SqlInserts
39 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Run time (seconds): -1
39 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Adding node: yb-tserver-n1:5433
40 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Adding node: yb-tserver-n2:5433
40 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Adding node: yb-tserver-n3:5433
40 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Num reader threads: 0, num writer threads: 1
41 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Num unique keys to insert: 500000
41 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Num keys to update: 1500000
41 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Num keys to read: 1500000
41 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Value size: 0
41 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Restrict values to ASCII strings: false
41 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Perform sanity check at end of app run: false
41 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Table TTL (secs): -141 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Local reads: false
42 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - Read only load: false
47 [main] INFO com.yugabyte.sample.common.CmdLineOpts  - SqlInserts workload: using driver set for load-balance = true
368 [main] INFO com.yugabyte.sample.apps.SqlInserts  - Created table: postgresqlkeyvalue
5394 [Thread-0] INFO com.yugabyte.sample.common.metrics.MetricsTracker  - Read: 0.00 ops/sec (0.00 ms/op), 0 total ops  |  Write: 475.02 ops/sec (2.09 ms/op), 2376 total ops  |  Uptime: 5025 ms |
```

This benchmark will run for about 1 minute giving you many values

This benchmark creates a table and doesn´t drop it in the end, so in order to avoid noise/interference from previous executions follow these steps:

1. connect to ysqlsh

```
./bin/ysqlsh -h <instance1-internal-ip-addr>
```

2. Connect to postgres database
```
yugabyte=# \c postgres
```

3. Drop table
```
yugabyte=# drop table postgresqlkeyvalue;
```

## Additional information

In this stage there were 6 factors tested: number of nodes, number of processor cores, replication factor, RAM, max user processes and max locked memory.

In Linux, ulimit is used to limit and control the usage of system resources (threads, files, and network connections) on a per-process or per-user basis. Therefore, in order to test max user processes and max locked memory factors, run the following commands:

1. To change max user processes

```
ulimit -u <value>
```

2. To change max locked memory

```
ulimit -l <value>
```

Notes:

1. You can only limit to lower values, so if you want to reset the value you will need to restart SSH connection

2. For more information check https://docs.yugabyte.com/preview/deploy/manual-deployment/system-config/

## Universal Scalability Law

In order to calculate the USL parameters, follow these steps:

Firstly, go to USL_calculus directory

```
cd USL_calculus
```

As the csv is already in repo, there's only the need to run the jar file with this csv file as input

```
java -jar esle-usl-1.0-SNAPSHOT.jar throughput.csv
```
