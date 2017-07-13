#!/bin/bash -ex

function finish {
  docker-compose down --rmi all
}
trap finish EXIT

# Generate reports folders locally
mkdir -p spec/reports features/reports

docker-compose down  --rmi all
# Build test container & start the cluster
docker-compose build
docker-compose up -d

sleep 5

# docker-compose exec possum possum account create cucumber

api_key=$(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key")
echo "api_key: $api_key"
# api_key=$(cat tmp.txt | tail -1 | awk '{print $4}' | tr -d '\r')

# Execute tests
docker-compose exec tests \
  env CONJUR_AUTHN_API_KEY=$(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key") \
  bash -c 'ci/test.sh'
# env CONJUR_AUTHN_API_KEY=$(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key") \
#     docker-compose run tests ci/test.sh
# $(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key")
