#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=apirubydev

docker-compose build

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --no-deps --rm --entrypoint conjur conjurctl data-key generate > data_key
fi

export CONJUR_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose exec cli bash
