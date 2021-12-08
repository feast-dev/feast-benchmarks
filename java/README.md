1. Prerequisites
```
docker
docker-compose

python3

ghz
```

2. Prepare feature repo
```
cd feature_repo; feast apply
```

3. Start docker compose
```
cd java; docker-compose up
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