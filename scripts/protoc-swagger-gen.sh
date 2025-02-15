#!/usr/bin/env bash

set -eo pipefail

mkdir -p ./tmp-swagger-gen
proto_dirs=$(find ./proto ./third_party/proto/cosmos ./third_party/proto/ibc -path -prune -o -name '*.proto' -print0 | xargs -0 -n1 dirname | sort | uniq)
for dir in $proto_dirs; do

  # generate swagger files (filter query files)
  query_file=$(find "${dir}" -maxdepth 1 \( -name 'query.proto' -o -name 'service.proto' \))
  if [[ ! -z "$query_file" ]]; then
    # 1. Get buf from https://github.com/bufbuild/buf/releases/tag/v1.0.0-rc12
    # Note that v1.0.0-rc12 is the last version with the "buf protoc" subcommand
    # 2. Get swagger protoc plugin with `go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@v1.16.0`

    buf protoc  \
    -I "proto" \
    -I "third_party/proto" \
    "$query_file" \
    --swagger_out=./tmp-swagger-gen \
    --swagger_opt=logtostderr=true \
    --swagger_opt=fqn_for_swagger_name=true \
    --swagger_opt=simple_operation_ids=true
  fi
done

# combine swagger files
# uses nodejs package `swagger-combine`.
# all the individual swagger files need to be configured in `config.json` for merging
npx swagger-combine ./client/docs/config.json -o ./client/docs/static/swagger/swagger.yaml -f yaml --continueOnConflictingPaths true --includeDefinitions true

# clean swagger files
rm -rf ./tmp-swagger-gen