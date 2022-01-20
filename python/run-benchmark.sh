#!/bin/bash


UNIQUE_REQUESTS_NUM=${UNIQUE_REQUESTS_NUM:-1000}
TARGET=${TARGET:-http://127.0.0.1}
NUM_SERVERS=${NUM_SERVERS:-8}
CONCURRENCY=${CONCURRENCY:-5}
RUN_TIME=${RUN_TIME:-5s}
WAIT_TIME=${WAIT_TIME:-1}

trap "exit" INT

single_run() {
	echo "Entity rows: $1; Features: $2; Concurrency: $3; RPS: $4"

	python3 request_generator.py \
		--endpoint ${TARGET} \
		--num-ports ${NUM_SERVERS} \
		--entity-rows $1 \
		--features $2 \
		--requests ${UNIQUE_REQUESTS_NUM} \
		--output requests-$1-$2.json

	echo "vegeta attack -format json -targets requests-$1-$2.json -connections $3 -duration ${RUN_TIME} -rate $4/1s | vegeta report"

	vegeta attack -format json -targets requests-$1-$2.json -connections $3 -duration ${RUN_TIME} -rate $4/1s | vegeta report

	sleep ${WAIT_TIME}
}

# single_run <entities> <features> <concurrency> <rps>


echo "Change only number of rows"

single_run 1 50 $CONCURRENCY 10

for i in $(seq 10 10 100); do single_run $i 50 $CONCURRENCY 10; done


echo "Change only number of features"

for i in $(seq 50 50 250); do single_run 1 $i $CONCURRENCY 10; done


echo "Change only number of requests"

for i in $(seq 10 10 100); do single_run 1 50 $CONCURRENCY $i; done

for i in $(seq 10 10 100); do single_run 1 250 $CONCURRENCY $i; done

for i in $(seq 10 10 100); do single_run 100 50 $CONCURRENCY $i; done

for i in $(seq 10 10 100); do single_run 100 250 $CONCURRENCY $i; done
