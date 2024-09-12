ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends vim curl

WORKDIR /src/conjur-api

COPY Gemfile conjur-api.gemspec VERSION ./
COPY lib/conjur-api/version.rb ./lib/conjur-api/

RUN bundle

COPY . ./

ENTRYPOINT ["/usr/local/bin/bundle", "exec"]
CMD ["rake", "jenkins"]
