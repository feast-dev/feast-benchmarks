package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"
	"sync"

	"github.com/feast-dev/feast/sdk/go/protos/feast/serving"
	"github.com/golang/protobuf/jsonpb"
	
	"github.com/kelseyhightower/envconfig"
	"google.golang.org/grpc"
	//"google.golang.org/protobuf/proto"
	//"google.golang.org/protobuf/encoding/prototext"

	"github.com/montanaflynn/stats"
)

type Config struct {
	FeastServingHost string `default:"localhost" split_words:"true"`
	FeastServingPort int    `default:"6566" split_words:"true"`
	RequestsPath     string `default:"requests.json" split_words:"true"`
	Concurrency      int    `default:"4" split_words:"true"`
	Requests         int    `default:"1000" split_words:"true"`
	RPS              int    `default:"100"`
}

var wg sync.WaitGroup

func main() {
	var c Config
	err := envconfig.Process("LOAD", &c)
	if err != nil {
		log.Fatal(err.Error())
	}

	conn, err := grpc.Dial(fmt.Sprintf("%s:%d", c.FeastServingHost, c.FeastServingPort), grpc.WithInsecure())
	if err != nil {
		log.Fatal(err)
	}
	client := serving.NewServingServiceClient(conn)

	reqCh := make(chan *serving.GetOnlineFeaturesRequest, 0)
	resultCh := make(chan time.Duration, c.Requests)

	ctx, _ := context.WithCancel(context.Background())

	requests := readRequests(c.RequestsPath)
	
	for i := 1; i <= c.Concurrency; i++ {
		wg.Add(1)
		go worker(i, ctx, client, reqCh, resultCh)
	}

	start := time.Now()

	run(c, requests, reqCh)
	
	close(reqCh)
	wg.Wait()

	totalTime := float64(time.Since(start)) / float64(time.Second)

	results := make([]float64, 0)
	for len(resultCh) > 0 {
  		results = append(results, float64(<-resultCh) / float64(time.Millisecond))
	}

	mean, _ := stats.Mean(results)
	log.Printf("Avg: %fms", mean)
	min, _ := stats.Min(results)
	log.Printf("Min: %fms", min)
	max, _ := stats.Max(results)
	log.Printf("Max: %fms", max)
	median, _ := stats.Median(results)
	log.Printf("Median: %fms", median)
	p95, _ := stats.Percentile(results, 95)
	log.Printf("95p: %fms", p95)
	p99, _ := stats.Percentile(results, 99)
	log.Printf("99p: %fms", p99)
	rps := float64(c.Requests) / totalTime
	log.Printf("RPS: %.2f", rps)	
}

func run(c Config, requests []*serving.GetOnlineFeaturesRequest, reqCh chan *serving.GetOnlineFeaturesRequest) {
	ticker := time.NewTicker(time.Duration(1000000 / c.RPS) * time.Microsecond)
	reqCounter := 0
	reqIdx := 0
	
	for {
    	select {
    		case <- ticker.C:
    			reqCounter += 1
    			if reqCounter >= c.Requests {
    				//log.Printf("stop %d", reqCounter)
    				ticker.Stop()
    				return
    			}

    			reqCh <- requests[reqIdx]
    			reqIdx += 1
    			if reqIdx == len(requests) {
    				reqIdx = 0
    			}
		}
	}
}

func readRequests(reqPath string) []*serving.GetOnlineFeaturesRequest {
	file, err := os.Open(reqPath)
	if err != nil {
		log.Fatal(err)
	}
	jsonDecoder := json.NewDecoder(file)
	_, err = jsonDecoder.Token()
	if err != nil {
		log.Fatal(err)
	}

	requests := make([]*serving.GetOnlineFeaturesRequest, 0)
	for jsonDecoder.More() {
		req := serving.GetOnlineFeaturesRequest{}
		err := jsonpb.UnmarshalNext(jsonDecoder, &req)
		if err != nil {
			log.Fatal(err)
		}
		requests = append(requests, &req)
	}
	return requests
}

func worker(workerId int, ctx context.Context, client serving.ServingServiceClient, reqCh <-chan *serving.GetOnlineFeaturesRequest, resultCh chan time.Duration) {
	defer wg.Done()

	for req := range reqCh {
		//log.Printf("Sending request. WorkerId %d", workerId)
		start := time.Now()

		//_, err := client.GetOnlineFeatures(ctx, req)
		client.GetOnlineFeatures(ctx, req)
		duration := time.Since(start)

		//println(prototext.Format(resp))

		//log.Printf("Retrieval %s; Success: %t. WorkerId: %d", duration, err == nil, workerId)
	
		resultCh <- duration
	}
}
