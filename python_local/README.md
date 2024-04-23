# Benchmarking Python Feature Server

Here we provide tools for benchmarking Python-based feature server with one online stores: Redis on a local Linux machine. Follow the instructions below to reproduce the benchmarks.

_Tested with: `feast 0.37.1`_

## Prerequisites

You need to have the following installed:
* Python `3.9+`
* Feast `0.37.0+`
* Docker
* Docker Compose `v2.x`
* Vegeta
* `parquet-tools`



## Generate Data

For all of the following benchmarks, you'll need to generate the data using `data_generator.py` under the top-level directory of this repo. Just `cd` to the main directory and run `python data_generator.py`. Please be aware that the timestamp of the generated parquet file has an experiation effect. If you try to use the generated data at a different day, it will fail the "feast materialize-increment" command in Step 3. Please generate this fake data again if no feature data is written into the Redis.  

The generated parquet file includes:  
1, 252 columns:  "entity" column, "event_timestamp" column and 250 fake "feature_[*]" columns.  
2, 10,000 rows.  
3, the value of the Datafame are randomg integers.  

The content of the parquet can be checked by following example commands:   
1, ```parquet-tools inspect generated_data.parquet```  
2, ```parquet-tools show --head 2 generated_data.parquet```  



## Redis

1. Disable the USAGE feature. Apply feature definitions to create a Feast repo. 

```
export FEAST_USAGE=False
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
./run-benchmark.sh  > perf.log
```

The report (or say results) of vegeta will be written to "pert.log" file.
