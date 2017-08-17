#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=apirubydev

docker-compose stop
docker-compose rm -f
