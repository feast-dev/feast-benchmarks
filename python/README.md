# Benchmarking Python Feature Server

Here we provide tools for benchmarking Python-based feature server with 3 online stores: Redis, AWS DynamoDB, and GCP Datastore. Follow the instructions below to reproduce the benchmarks.

## Prerequisites

You need to have the following installed:
* Feast 0.17+
* Docker
* Docker Compose
* Vegeta

## Generate Data

For all of the following benchmarks, you'll need to generate the data using `data_generator.py` under the top-level directory of this repo. Just `cd` to the main directory and run `python data_generator.py`.

## Redis

1. Apply feature definitions to create a Feast repo.
```
cd feature_repos/redis
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
sed -i 's/redis:6379/localhost:6379/g' feature_store.yaml # this is unfortunately necessary because inside docker feature servers resolve Redis host name as `redis`, but since we're running materialization from shell, Redis is accessible on localhost.
feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")
sed -i 's/localhost:6379/redis:6379/g' feature_store.yaml # make sure to change this back, since it can mess up with feature servers if you run another docker-compose command later. 
```

4. Run Benchmarks
```
cd ../..
RUN_TIME=1m ./run-benchmark.sh
```

## AWS DynamoDB

TODO

## GCP Datastore

TODO
