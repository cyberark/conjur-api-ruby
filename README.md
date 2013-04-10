# Conjur::API

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'conjur-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conjur-api

## Usage

Default service ports:
 - authn: 5000,
 - authz: 5100.

```ruby
ENV['CONJUR_ACCOUNT'] = 'account'
conjur = Conjur::API.new_from_key 'admin', 'vJfQbiieBcv4SlxTZ7ULznc1zHZ4z+0sx5to3hLOic0='
some_user = conjur.user 'foo'

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
