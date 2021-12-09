#!/bin/bash


GHZ_FLAGS=${GHZ_FLAGS:-"--insecure -i protos/ --proto ./protos/ServingService.proto --call feast.serving.ServingService.GetOnlineFeaturesV2 --cpus=4 --skipFirst=100 --timeout=100ms"}

TOTAL_REQUESTS_NUM=${TOTAL_REQUESTS_NUM:-10000}
UNIQUE_REQUESTS_NUM=${UNIQUE_REQUESTS_NUM:-1000}
TARGET=${TARGET:-localhost:6566}
CONCURRENCY=${CONCURRENCY:-5}

trap "exit" INT

single_run() {
	echo "Entity rows: $1; Features: $2; Concurrency: $3; RPS: $4"

	python3 request_generator.py \
		--entity-rows $1 \
		--features $2 \
		--requests ${UNIQUE_REQUESTS_NUM} \
		--output requests-$1-$2.json

	echo "ghz ${GHZ_FLAGS} \\
-n ${TOTAL_REQUESTS_NUM} \\
--data-file requests-$1-$2.json \\
--rps $4 \\
-c $3 \\
$TARGET"

	ghz ${GHZ_FLAGS}\
		-n ${TOTAL_REQUESTS_NUM} \
		--data-file requests-$1-$2.json \
		--rps $4 \
		-c $3 \
		$TARGET
}


# single_run <entities> <features> <concurrency> <rps>


echo "Change only number of rows"

single_run 1 50 $CONCURRENCY 100

for i in $(seq 10 10 100); do single_run $i 50 $CONCURRENCY 100; done


echo "Change only number of features"

for i in $(seq 50 50 250); do single_run 1 $i $CONCURRENCY 100; done


echo "Change only number of requests"

for i in $(seq 100 100 1000); do single_run 1 50 $CONCURRENCY $i; done



echo "Fix uptime to 99.9% with 100ms timeout"

for i in $(seq 10 10 50); do single_run 1 50 $i 0; done

for i in $(seq 10 10 50); do single_run 1 250 $i 0; done

for i in $(seq 2 2 10); do single_run 100 50 $i 0; done

for i in $(seq 2 2 10); do single_run 100 250 $i 0; done