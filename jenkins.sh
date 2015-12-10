#!/bin/bash -e

docker build -t api-ruby .

docker run --rm \
-v $PWD:/src \
api-ruby \
bash -c '''
bundle
bundle exec rake jenkins
'''
