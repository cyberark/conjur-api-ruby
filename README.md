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

### Programmatic configuration

To configure the API to connect to Conjur, specify the account and appliance_url (both of which are required) like this:

```ruby
Conjur.configuration.account = 'my-account'
Conjur.configuration.appliance_url = 'https://conjur.mydomain.com/api'
```

You can also specify these values in environment variables, which is often a bit more convenient.  Environment variables are mapped to configuration variables by prepending CONJUR_ to the all-caps name of the configuration variable, for example, `appliance_url` is `CONJUR_APPLIANCE_URL`, `account` is `CONJUR_ACCOUNT`, etc.

In either case, if you are using Conjur's self-signed cert, you will also need to configure certificate trust:

```ruby
OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.add_file "/path/to/conjur-youraccount.pem"
```

### Using Conjur system configuraiton

To instantiate the API using configuration stored stored in `/etc/conjur.conf` and/or `~/.conjurrc`:

```ruby
require 'conjur/cli'
Conjur::Config.load
Conjur::Config.apply
conjur = Conjur::API.new_from_key username, api_key
```

`username` and `api_key` can also be provided by environment variables: `CONJUR_AUTHN_LOGIN` and `CONJUR_AUTHN_API_KEY`. If the login is a host, the `CONJUR_AUTHN_LOGIN` should be prefixed with `host/`. For example: `host/myhost.example.com`.

If the login and API key are provided by `netrc` or by the environment, you can construct an API client using:

```ruby
conjur = Conjur::Authn.connect
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
