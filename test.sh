#!/bin/bash -ex

docker build -t api-test -f Dockerfile.test .
image_id=api-test

function finish {
	docker rm -f $pg_cid
	docker rm -f $server_cid
    if [ ! -z "$KEEP_IMAGE" ]; then
      docker rmi $image_id
    fi
}
trap finish EXIT

possum_tag=push-image_170626_0.1.0
possum=registry.tld/possum:${possum_tag}

export POSSUM_DATA_KEY="$(docker run --rm ${possum} data-key generate)"

pg_cid=$(docker run -d postgres:9.3)

mkdir -p spec/reports

server_cid=$(docker run -d \
	--link $pg_cid:pg \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	${possum} server)

admin_api_key=( $(cat ci/setup-account.sh | docker exec -i $server_cid /bin/bash | tail -1) )

mkdir -p spec/reports features/reports

docker run \
	-i \
	--rm \
	--link $pg_cid:pg \
	--link $server_cid:possum \
    -v $PWD/spec/reports:/src/spec/reports \
    -v $PWD/features/reports:/src/features/reports \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	-e CONJUR_APPLIANCE_URL=http://possum \
	-e CONJUR_ACCOUNT=cucumber \
    -e CONJUR_AUTHN_API_KEY=${admin_api_key[3]} \
    $image_id /bin/bash ci/test.sh "$@"

