# Benchmarking Python Feature Server

Here we provide tools for benchmarking Python-based feature server with 3 online stores: Redis, AWS DynamoDB, and GCP Datastore. Follow the instructions below to reproduce the benchmarks.

_Tested with: `feast 0.25.1`_

## Prerequisites

You need to have the following installed:
* Python `3.8+`
* Feast `0.25+`
* Docker
* Docker Compose `v2.x`
* Vegeta
* `parquet-tools`

All these benchmarks are run on an EC2 instance (c5.4xlarge, 16vCPU, 32GiB memory) or a GCP GCE instance (c2-standard-16, 16 vCPU, 64GiB memory), on the same region as the target online stores.

**Note**: see [here](cloud_machines.md) for details on how to provision the cloud instances to run the tests.

## Generate Data

For all of the following benchmarks, you'll need to generate the data using `data_generator.py` under the top-level directory of this repo. Just `cd` to the main directory and run `python data_generator.py`.

## Redis

1. Apply feature definitions to create a Feast repo.

```
cd python/feature_repos/redis
feast apply
```

2. Deploy Redis & feature servers using docker-compose

```
cd ../../docker/redis
docker-compose up -d
```
If everything goes well, you should see an output like this:

```
Creating redis_redis_1 ... done
Creating redis_feast_1  ... done
Creating redis_feast_2  ... done
Creating redis_feast_3  ... done
Creating redis_feast_4  ... done
Creating redis_feast_5  ... done
Creating redis_feast_6  ... done
Creating redis_feast_7  ... done
Creating redis_feast_8  ... done
Creating redis_feast_9  ... done
Creating redis_feast_10 ... done
Creating redis_feast_11 ... done
Creating redis_feast_12 ... done
Creating redis_feast_13 ... done
Creating redis_feast_14 ... done
Creating redis_feast_15 ... done
Creating redis_feast_16 ... done
```

3. Materialize data to Redis

```
cd ../../feature_repos/redis
# This is unfortunately necessary because inside docker feature servers resolve
# Redis host name as `redis`, but since we're running materialization from shell,
# Redis is accessible on localhost:
sed -i 's/redis:6379/localhost:6379/g' feature_store.yaml
feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")
# Make sure to change this back, since it can mess up with feature servers
# if you run another docker-compose command later:
sed -i 's/localhost:6379/redis:6379/g' feature_store.yaml
```

4. Check that feature servers are working & they have materialized data

```
cd ../../..
parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6
```
This should return something like this:

```
+----------+
|   entity |
|----------|
|       94 |
|     1992 |
|     4475 |
```

Put these numbers into an env variable with:

```
TEST_ENTITY_IDS=`parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6 | tail -n 3 | sed 's/|//g' | paste -d, -s`
echo $TEST_ENTITY_IDS
```
(which should output something like `94  ,   1992   ,   4475  `)


Query the feature server with

```
curl -X POST \
  "http://127.0.0.1:6566/get-online-features" \
  -H "accept: application/json" \
  -d "{
    \"feature_service\": \"feature_service_0\",
    \"entities\": {
      \"entity\": [$TEST_ENTITY_IDS]
    }
  }" | jq
```


In the output, make sure that `"values"` field contains none of the null
values. It should look something like this:

```
    {
      "values": [
        4475,
        1551,
        9889,        
```

5. Run Benchmarks

```
cd python
./run-benchmark.sh
```

## AWS DynamoDB

For this benchmark, you'll need to have AWS credentials configured in `~/.aws/credentials`.

1. Apply feature definitions to create a Feast repo.

```
cd feature_repos/dynamo
feast apply
```

2. Deploy feature servers using docker-compose

```
cd ../../docker/dynamo
docker-compose up -d
```
If everything goes well, you should see an output like this:

```
Creating dynamo_feast_1  ... done
Creating dynamo_feast_2  ... done
Creating dynamo_feast_3  ... done
Creating dynamo_feast_4  ... done
Creating dynamo_feast_5  ... done
Creating dynamo_feast_6  ... done
Creating dynamo_feast_7  ... done
Creating dynamo_feast_8  ... done
Creating dynamo_feast_9  ... done
Creating dynamo_feast_10 ... done
Creating dynamo_feast_11 ... done
Creating dynamo_feast_12 ... done
Creating dynamo_feast_13 ... done
Creating dynamo_feast_14 ... done
Creating dynamo_feast_15 ... done
Creating dynamo_feast_16 ... done
```

3. Materialize data to DynamoDB

```
cd ../../feature_repos/dynamo
feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")
```

4. Check that feature servers are working & they have materialized data

```
cd ../../..
parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6
```
This should return something like this:

```
+----------+
|   entity |
|----------|
|       94 |
|     1992 |
|     4475 |
```

Put these numbers into an env variable with:

```
TEST_ENTITY_IDS=`parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6 | tail -n 3 | sed 's/|//g' | paste -d, -s`
echo $TEST_ENTITY_IDS
```
(which should output something like `94  ,   1992   ,   4475  `)

Query the feature server with

```
curl -X POST \
  "http://127.0.0.1:6566/get-online-features" \
  -H "accept: application/json" \
  -d "{
    \"feature_service\": \"feature_service_0\",
    \"entities\": {
      \"entity\": [$TEST_ENTITY_IDS]
    }
  }" | jq
```

In the output, make sure that `"values"` field contains none of the null values. It should look something like this:

```
    {
      "values": [
        4475,
        1551,
        9889,        
```

5. Run Benchmarks

```
cd python
./run-benchmark.sh
```

## GCP Datastore

For this benchmark, you need GCP credentials accessible. Here it is assumed that it's all in
`${HOME}/.config/gcloud`, which will be available to the docker containers running
the feature server. (Adjust as needed by inspecting the `docker-compose.yml`).

1. Apply feature definitions to create a Feast repo.

```
cd feature_repos/datastore
feast apply
```

2. Deploy feature servers using docker-compose

```
cd ../../docker/datastore
docker-compose up -d
```
If everything goes well, you should see an output like this:

```
Creating datastore_feast_1  ... done
Creating datastore_feast_2  ... done
Creating datastore_feast_3  ... done
Creating datastore_feast_4  ... done
Creating datastore_feast_5  ... done
Creating datastore_feast_6  ... done
Creating datastore_feast_7  ... done
Creating datastore_feast_8  ... done
Creating datastore_feast_9  ... done
Creating datastore_feast_10 ... done
Creating datastore_feast_11 ... done
Creating datastore_feast_12 ... done
Creating datastore_feast_13 ... done
Creating datastore_feast_14 ... done
Creating datastore_feast_15 ... done
Creating datastore_feast_16 ... done
```

> _Note_: The Python google package requires not only the credentials to be accessible
> (in read-write mode, as can be seen in the Datastore docker-compose.yml),
> but also the google cloud SDK to be installed.
> For this reason there is an additional step in the Dockerfile for Datastore,
> which handles the installation. [Reference](https://stackoverflow.com/questions/28372328/how-to-install-the-google-cloud-sdk-in-a-docker-image).

3. Materialize data to Datastore

```
cd ../../feature_repos/datastore
feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")
```

4. Check that feature servers are working & they have materialized data

```
cd ../../..
parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6
```
This should return something like this:

```
+----------+
|   entity |
|----------|
|       94 |
|     1992 |
|     4475 |
```

Put these numbers into an env variable with:

```
TEST_ENTITY_IDS=`parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6 | tail -n 3 | sed 's/|//g' | paste -d, -s`
echo $TEST_ENTITY_IDS
```
(which should output something like `94  ,   1992   ,   4475  `)


Query the feature server with

```
curl -X POST \
  "http://127.0.0.1:6566/get-online-features" \
  -H "accept: application/json" \
  -d "{
    \"feature_service\": \"feature_service_0\",
    \"entities\": {
      \"entity\": [$TEST_ENTITY_IDS]
    }
  }" | jq
```

In the output, make sure that `"values"` field contains none of the null values. It should look something like this:

```
    {
      "values": [
        4475,
        1551,
        9889,        
```

5. Run Benchmarks

```
cd python
./run-benchmark.sh
```


## Cassandra

This runs on a single-node Cassandra cluster running in Docker alongside the
benchmarking containers.

1. Start the docker containers:

```
cd docker/cassandra
docker-compose up -d
```

If everything goes well, you should see an output like this:

```
 ⠿ Network cassandra_default        Created       0.0s
 ⠿ Container cassandra-cassandra-1  Started       0.6s
 ⠿ Container cassandra-feast-16     Started       1.0s
 ⠿ Container cassandra-feast-1      Started       1.5s
 ⠿ Container cassandra-feast-8      Started       3.0s
 ⠿ Container cassandra-feast-4      Started       2.4s
 ⠿ Container cassandra-feast-2      Started       2.4s
 ⠿ Container cassandra-feast-14     Started       2.2s
 ⠿ Container cassandra-feast-5      Started       1.5s
 ⠿ Container cassandra-feast-3      Started       2.8s
 ⠿ Container cassandra-feast-13     Started       0.8s
 ⠿ Container cassandra-feast-9      Started       1.3s
 ⠿ Container cassandra-feast-11     Started       1.7s
 ⠿ Container cassandra-feast-15     Started       0.9s
 ⠿ Container cassandra-feast-6      Started       2.8s
 ⠿ Container cassandra-feast-12     Started       2.0s
 ⠿ Container cassandra-feast-7      Started       2.5s
 ⠿ Container cassandra-feast-10     Started       1.8s
```

Wait about 60-90 seconds for Cassandra to fully start. Then you can proceed (if not ready yet, the next command will error and you can retry it a little later).

2. Create the destination keyspace in Cassandra: check the output of this command to make sure `feast_test` is now here.

```
docker exec -it cassandra-cassandra-1 cqlsh -e \
  "CREATE KEYSPACE feast_test WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 1}; DESC KEYSPACES;"

```

3. From the host machine, provision the feature store:

```
cd ../../feature_repos/cassandra/

# This is unfortunately necessary because inside docker feature servers resolve
# Cassandra host name as `cassandra`, but since we're running materialization from shell,
# Cassandra is accessible on localhost:
sed -i 's/- cassandra/- localhost/g' feature_store.yaml
feast apply
# Make sure to change this back, since it can mess up with feature servers
# if you run another docker-compose command later:
sed -i 's/- localhost/- cassandra/g' feature_store.yaml
```


4. Similarly, materialize from the host machine:

```
# This is unfortunately necessary because inside docker feature servers resolve
# Cassandra host name as `cassandra`, but since we're running materialization from shell,
# Cassandra is accessible on localhost:
sed -i 's/- cassandra/- localhost/g' feature_store.yaml
feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")
# Make sure to change this back, since it can mess up with feature servers
# if you run another docker-compose command later:
sed -i 's/- localhost/- cassandra/g' feature_store.yaml
```

3b. A workaround for the Dockerized feast to work

The Docker container have a _copy_ of the registry directory, including data/registry.db.
But the image gets done before the `apply` step above (it is inevitable if we want
to create the keyspace and have the Cassandra part of the `docker-compose`),
so the Docker `feast`s have not the updated `registry.db`. For the time being, a workaround
is as follows:

```
docker cp data/registry.db cassandra-feast-1:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-2:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-3:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-4:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-5:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-6:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-7:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-8:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-9:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-10:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-11:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-12:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-13:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-14:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-15:/feature_repo/data/registry.db
docker cp data/registry.db cassandra-feast-16:/feature_repo/data/registry.db

cd ../../docker/cassandra/
docker-compose restart
cd ../../feature_repos/cassandra/
```

5. Check that feature servers are working & they have materialized data

```
cd ../../..
parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6
```
This should return something like this:

```
+----------+
|   entity |
|----------|
|       94 |
|     1992 |
|     4475 |
```

Put these numbers into an env variable with:

```
TEST_ENTITY_IDS=`parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6 | tail -n 3 | sed 's/|//g' | paste -d, -s`
echo $TEST_ENTITY_IDS
```
(which should output something like `94  ,   1992   ,   4475  `)


Query the feature server with

```
curl -X POST \
  "http://127.0.0.1:6566/get-online-features" \
  -H "accept: application/json" \
  -d "{
    \"feature_service\": \"feature_service_0\",
    \"entities\": {
      \"entity\": [$TEST_ENTITY_IDS]
    }
  }" | jq
```

In the output, make sure that `"values"` field contains none of the null values. It should look something like this:

```
    {
      "values": [
        4475,
        1551,
        9889,        
```

6. Run Benchmarks

```
cd python
./run-benchmark.sh
```


## Astra DB

Ensure you have an Astra DB instance in the same AWS region as your benchmarking
client. To connect to it you need the Client ID and the Client Secret from a
database token, as well as the "secure connect bundle" zip-file which should
be placed inside the `python/feature_repos/astra_db/` directory.

Adjust file `feature_store.yaml` in that directory to reflect Client ID, Client
Secret, database keyspace name, AWS region name and secure-connect-bundle filename.

**Note**: in order to be able to share the same `feature_store.yaml` from both
the Dockerized `feast` instances and the one on the host machine,
please put the secure connect bundle in the `python/feature_repos/astra_db/`
directory itself and refer to it as `./secure-connect-DATABASENAME.zip`
(i.e. with a relative path).

1. Apply feature definitions to create a Feast repo.

```
cd feature_repos/astra_db
feast apply
```

2. Deploy feature servers using docker-compose

```
cd ../../docker/astra_db
docker-compose up -d
```
If everything goes well, you should see an output like this:

```
 ⠿ Network astra_db_default     Created        0.0s
 ⠿ Container astra_db-feast-1   Started        2.7s
 ⠿ Container astra_db-feast-16  Started        2.8s
 ⠿ Container astra_db-feast-3   Started        2.4s
 ⠿ Container astra_db-feast-5   Started        1.4s
 ⠿ Container astra_db-feast-11  Started        1.8s
 ⠿ Container astra_db-feast-4   Started        1.6s
 ⠿ Container astra_db-feast-2   Started        1.2s
 ⠿ Container astra_db-feast-6   Started        0.8s
 ⠿ Container astra_db-feast-12  Started        2.1s
 ⠿ Container astra_db-feast-7   Started        3.0s
 ⠿ Container astra_db-feast-8   Started        0.8s
 ⠿ Container astra_db-feast-10  Started        2.8s
 ⠿ Container astra_db-feast-14  Started        1.2s
 ⠿ Container astra_db-feast-15  Started        2.9s
 ⠿ Container astra_db-feast-13  Started        1.8s
 ⠿ Container astra_db-feast-9   Started        2.3s
```

3. Materialize data to Astra DB

```
cd ../../feature_repos/astra_db
feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")
```

4. Check that feature servers are working & they have materialized data

```
cd ../../..
parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6
```
This should return something like this:

```
+----------+
|   entity |
|----------|
|       94 |
|     1992 |
|     4475 |
```

Put these numbers into an env variable with:

```
TEST_ENTITY_IDS=`parquet-tools show --columns entity generated_data.parquet 2>/dev/null | head -n 6 | tail -n 3 | sed 's/|//g' | paste -d, -s`
echo $TEST_ENTITY_IDS
```
(which should output something like `94  ,   1992   ,   4475  `)


Query the feature server with

```
curl -X POST \
  "http://127.0.0.1:6566/get-online-features" \
  -H "accept: application/json" \
  -d "{
    \"feature_service\": \"feature_service_0\",
    \"entities\": {
      \"entity\": [$TEST_ENTITY_IDS]
    }
  }" | jq
```

In the output, make sure that `"values"` field contains none of the null values. It should look something like this:

```
    {
      "values": [
        4475,
        1551,
        9889,        
```

5. Run Benchmarks

```
cd python
./run-benchmark.sh
```
