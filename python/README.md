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
