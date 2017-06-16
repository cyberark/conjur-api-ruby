FROM ruby:2.3

WORKDIR /src/conjur-api

COPY Gemfile conjur-api.gemspec ./
COPY lib/conjur-api/version.rb ./lib/conjur-api/

RUN bundle

COPY . ./
