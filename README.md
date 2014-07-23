# Conjur::API

Programmatic Ruby access to the Conjur API.

## Installation

Add this line to your application's Gemfile:

    gem 'conjur-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conjur-api

## Usage

To instantiate the API, using configuration stored stored in `~/.conjurrc`:

```ruby
require 'conjur/cli'
Conjur::Config.load
conjur = Conjur::API.new_from_key username, api_key
```

You can find the username and api_key in ~/.netrc after you've logged in.

Fancier/different init scenarios are possible but this should be a good start!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
