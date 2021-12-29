module github.com/feast-dev/aws-lambda-benchmarks/go_client

go 1.17

require (
	github.com/feast-dev/feast/sdk/go v0.9.2
	github.com/go-redis/redis/v8 v8.11.4
	github.com/golang/protobuf v1.5.2
	github.com/kelseyhightower/envconfig v1.4.0
	github.com/montanaflynn/stats v0.6.6
	google.golang.org/grpc v1.31.0
	google.golang.org/protobuf v1.27.1
)

require (
	cloud.google.com/go v0.62.0 // indirect
	github.com/cespare/xxhash/v2 v2.1.2 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/golang/groupcache v0.0.0-20200121045136-8c9f03a8e57e // indirect
	github.com/opentracing-contrib/go-grpc v0.0.0-20200813121455-4a6760c71486 // indirect
	github.com/opentracing/opentracing-go v1.1.0 // indirect
	go.opencensus.io v0.22.4 // indirect
	golang.org/x/net v0.0.0-20210428140749-89ef3d95e781 // indirect
	golang.org/x/oauth2 v0.0.0-20200107190931-bf48bf16ab8d // indirect
	golang.org/x/sys v0.0.0-20210423082822-04245dca01da // indirect
	golang.org/x/text v0.3.6 // indirect
	google.golang.org/api v0.30.0 // indirect
	google.golang.org/appengine v1.6.6 // indirect
	google.golang.org/genproto v0.0.0-20200804131852-c06518451d9c // indirect
)

replace github.com/feast-dev/feast/sdk/go => github.com/pyalex/feast/sdk/go v0.0.0-20211222163450-f97c0397ba60
