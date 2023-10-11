# ESLE-Project

## Repository structure

 1. sysbench: contains Dockerfile and script to run benchmark as a docker container for our tested application.
 2. scalability_bench: contains Dockerfile and script to run benchmark as a docker container for our tested application.
 3. USL_calculus: contains app for running linear regression to use its results for Universal Scalability Law analysis. 
 4. plots.xlsx: excel file containing benchmark measurements and plots.
 5. yb-docker-ctl: a tool to create and manage docker cluster.  
 6. README.md: repository description and "how to run" instruction. 

## How to run
  YugabyteDB is already conteinerized, so there is no need in additional steps to run it in Docker. According to official documentation we can run 1 node cluser like this:
```
docker run -d --name yugabyte  -p7000:7000 -p9000:9000 -p5433:5433 -p9042:9042 yugabytedb/yugabyte:2.19.2.0-b121 bin/yugabyted start --daemon=false
```
However, we want to run a multinode cluster. For this purposes, we decided to use an ofiicial tool called yb-docker-ctl. With this tool, we can easily run a cluster with predefined replication factor and then add additional nodes if needed. You can download it here: https://github.com/yugabyte/yugabyte-db/blob/master/bin/yb-docker-ctl. Or with the following command:
```
wget https://raw.githubusercontent.com/yugabyte/yugabyte-db/master/bin/yb-docker-ctl && chmod +x yb-docker-ctl
```
Unfortunately, the original tool we downloaded cannot be executed. If you run it, you will see the following error:
```
Traceback (most recent call last):
  File "./yb-docker-ctl", line 545, in <module>
    YBDockerControl().run()
  File "./yb-docker-ctl", line 518, in run
    self.create_clusters()
  File "./yb-docker-ctl", line 370, in create_clusters
    self.start_cluster(server_type, node_id, None)
  File "./yb-docker-ctl", line 332, in start_cluster
    server_cmds.extend(['--fs_data_dirs={}'.format(",".join(self.volumes))])
TypeError: can only join an iterable
```
To solve this problem, you have to change line 16 in the file to:
```
CONTAINER_CONFIG_CMD = 'docker inspect -f "{{json .Config.%s}}" %s'
```
After that you can create the cluster like this:        !!!Note!!! Python has to be installed to run the file. 
```
python ./yb-docker-ctl create
```
Replication factor can be set with the flag "--rf" like:
```
python ./yb-docker-ctl create --rf 3 
```
It will create 3 master server and 3 tserver and connect them to each other making a working cluster in local machine.
```
ID             PID        Type       Node                 URL
       Status          Started At
211b827424c0   2985       tserver    yb-tserver-n3        http://172.24.0.7:9001    Running         2023-10-11T20:07:25.671995513Z
c736b8198b3d   2902       tserver    yb-tserver-n2        http://172.24.0.6:9001    Running         2023-10-11T20:07:25.087625192Z
e29506104781   2818       tserver    yb-tserver-n1        http://172.24.0.5:9001    Running         2023-10-11T20:07:24.491864719Z
9faf7fd43693   2687       master     yb-master-n3         http://172.24.0.4:7001    Running         2023-10-11T20:07:23.767279992Z
ee7092e03140   2594       master     yb-master-n2         http://172.24.0.3:7001    Running         2023-10-11T20:07:23.17029446Z
6fcfb4172cd5   2507       master     yb-master-n1         http://172.24.0.2:7001    Running         2023-10-11T20:07:22.427481075Z
```
You can add more nodes (tservers) without changing the replication factor with following command:
```
python ./yb-docker-ctl add_node
```
Or remove it:
```
python ./yb-docker-ctl remove_node
```
These are basic and most common usages of the tool. Additional command and description can be found here: https://docs.yugabyte.com/preview/admin/yb-docker-ctl/ .

The yb-docker-ctl runs containers in virtual network with name "yb-net". Keep it in mind to be able to run benchmarks correctly.

### sysbench 
We have prepared everything to run the sysbench easily. In directory "sysbench" there are Dockerfile and scipt to run benchmark as a docker container. Our predefined parameters run OLTP_READ_ONLY benchmark for 5 tables with 100000 rows in each for 60 seconds. Number of thread is specified while running a container with the benchmark. When it is finished, it also drops all created tables to keep original state. You can find more information here: https://docs.yugabyte.com/preview/benchmark/sysbench-ysql/ or https://github.com/akopytov/sysbench .
First, we need to build an image. 
```
docker build -t sysbench:latest . 
```
When you have already started a cluster, the sysbench can be run with following command: 
```
docker run -it --net yb-net sysbench 10
```
Last parameter specifies number of threads.
Output:
```
> docker run -it --network yb-net bench 10
running with 10 threads
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Creating table 'sbtest1'...
Inserting 100000 records into 'sbtest1'
Creating a secondary index on 'sbtest1'...
Creating table 'sbtest2'...
Inserting 100000 records into 'sbtest2'
Creating a secondary index on 'sbtest2'...
Creating table 'sbtest3'...
Inserting 100000 records into 'sbtest3'
Creating a secondary index on 'sbtest3'...
Creating table 'sbtest4'...
Inserting 100000 records into 'sbtest4'
Creating a secondary index on 'sbtest4'...
Creating table 'sbtest5'...
Inserting 100000 records into 'sbtest5'
Creating a secondary index on 'sbtest5'...
: not found4:
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Running the test with following options:
Number of threads: 10
Initializing random number generator from current time


Initializing worker threads...

Threads started!

SQL statistics:
    queries performed:
        read:                            1918
        write:                           0
        other:                           274
        total:                           2192
    transactions:                        137    (6.54 per sec.)
    queries:                             2192   (104.61 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          20.9500s
    total number of events:              137

Latency (ms):
         min:                                  894.99
         avg:                                 1502.40
         max:                                 2477.03
         95th percentile:                     2045.74
         sum:                               205828.36

Threads fairness:
    events (avg/stddev):           13.7000/0.46
    execution time (avg/stddev):   20.5828/0.26

: not found5:
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Dropping table 'sbtest1'...
Dropping table 'sbtest2'...
Dropping table 'sbtest3'...
Dropping table 'sbtest4'...
Dropping table 'sbtest5'...
: not found6:
finished
```

### Scalability benchmark

We also prepared another benchmark called Scalability, in other words it is a workload simulator. In directory "scalability_bench" there are Dockerfile and scipt to run benchmark as a docker container. Our predefined parameters run INSERT benchmark with 500000 unique keys parameter and workload type SqlInserts. Servers and number of threads are specified while running a container with the benchmark. More info here: https://docs.yugabyte.com/preview/benchmark/scalability/scaling-queries-ysql/ .

First, we need to build an image. 
```
docker build -t scale:latest . 
```
When you have already started a cluster, the benchmark can be run with following command: 
```
docker run -it --net yb-net scale yb-tserver-n1:5433,yb-tserver-n2:5433,yb-tserver-n3:5433 32
```
Last two parameters specify servers and number of clients respectively. 
Output: 
```
> docker run -it --net yb-net scale yb-tserver-n1:5433,yb-tserver-n2:5433,yb-tserver-n3:5433 1
running for yb-tserver-n1:5433,yb-tserver-n2:5433,yb-tserver-n3:5433 nodes and  1 threads
: not found3:
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
It will keep simulating the workload until we stop the container. 

### Universal Scalability Law

In order to calculate the USL parameters, follow these steps:

Firstly, go to USL_calculus directory

```
cd USL_calculus
```

As the csv is already in repo, there's only the need to run the jar file with this csv file as input

```
java -jar esle-usl-1.0-SNAPSHOT.jar throughput.csv
```