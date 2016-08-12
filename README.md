# Possum::Api

A basic library to access Possum service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'possum-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install possum-api

## Usage

```ruby
require 'possum'

possum = Possum::Client.new url: "http://possum.example.org"
possum.login 'example', 'admin', 'secret'

possum.get '/resources/org/chunky/bacon'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/conjurinc/possum-api.

