1. Prerequisites
```
docker
docker-compose

python3
python3-pip

ghz
```

See [docker install guide](https://docs.docker.com/engine/install/ubuntu/),
[docker-compose install guide](https://docs.docker.com/compose/install/) and [ghz install guide](https://ghz.sh/docs/install) to install latest versions.

2. Prepare feature repo
```
pip3 install feast[redis]

cd feature_repo; feast apply
```

3. Start docker compose
```
cd java; docker-compose up -d
```
Docker compose will expose too ports:
* 16379 - redis
* 6566 - Feast feature server

4. Generate dataset and write it into online store
```
python data_generator
cd feature_repo; feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")
```

5. Generate requests
```
cd java; python request_generator --output requests.json
```

6. Run benchmark
```
ghz --insecure -i protos/ --proto ./protos/ServingService.proto --data-file requests.json --call feast.serving.ServingService.GetOnlineFeaturesV2 -n 10000 -c 5 localhost:6566
```