1. Prerequisites
```
docker
docker-compose

python3
python3-pip

golang >= 1.17
```

See [docker install guide](https://docs.docker.com/engine/install/ubuntu/) and
[docker-compose install guide](https://docs.docker.com/compose/install/) to install latest versions.

2. Build Feast Go Benchmark Client
```
cd go_client/ && go build -o feast-go-client && cd -
cp go_client/feast-go-client java/
```

3. Prepare feature repo
```
pip3 install 'feast[redis]'

cd java/feature_repos/redis && feast apply && cd -
```

4. Start docker compose
```
cd java && docker-compose up -d && cd -
```
Docker compose will expose too ports:
* 16379 - redis
* 6566 - Feast feature server

5. Generate dataset and write it into online store
```
python data_generator.py
cd java/feature_repos/redis && feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S") && cd -
```

6. Run benchmark
```
cd java && ./run-benchmark.sh
```

### Results

We ran this benchmark on single EC2 machine (c5.4xlarge) with 16 vCPU.
Results are provided in [this spreadsheet](https://docs.google.com/spreadsheets/d/1MOW-Qccd-zCJ-3i_WL88sJFWWkjyiVtKXO0c7yHmjzk/edit?usp=sharing).