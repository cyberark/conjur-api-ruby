# Conjur::API

Programmatic Ruby access to the Conjur API.

# Installation

Add this line to your application's Gemfile:

    gem 'conjur-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conjur-api

# Usage

Connecting to Conjur is a two-step process:

* **Configuration** Instruct the API where to find the Conjur endpoint and how to secure the connection.
* **Authentication** Provide the API with credentials that it can use to authenticate.

## Configuration

The simplest way to configure the Conjur API is to use the configuration file stored on the machine.
If you have configured the machine with [conjur init](http://developer.conjur.net/reference/tools/init.html),
it's default location is `~/.conjurrc`. 

The Conjur configuration process also checks `/etc/conjur.conf` for global settings. This is typically used
in server environments.

For custom scenarios, the location of the file can be overridden using the `CONJURRC` environment variable. 

You can load the Conjur configuration file using the following Ruby code:

```ruby
require 'conjur/cli'
Conjur::Config.load
Conjur::Config.apply
```

**Note** this code requires the [conjur-cli](https://github.com/conjurinc/cli-ruby) gem, which should also be in your
gemset or bundle.

## Authentication

Once Conjur is configured, the connection can be established like this:

```
conjur = Conjur::Authn.connect nil, noask: true
```

To [authenticate](http://developer.conjur.net/reference/services/authentication/authenticate.html), the API client must
provide a `login` name and `api_key`. The `Conjur::Authn.connect` will attempt the following, in order:

1. Look for `login` in environment variable `CONJUR_AUTHN_LOGIN`, and `api_key` in `CONJUR_AUTHN_API_KEY` 
2. Look for credentials on disk. The default credentials file is `~/.netrc`. The location of the credentials file
can be overridden using the configuration file `netrc_path` option. 
3. Prompt for credentials. This can be disabled using the option `noask: true`.

## Connecting Without Files

It's possible to configure and authenticate the Conjur connection without using any files, and without requiring
the `conjur-cli` gem.

To accomplish this, apply the configuration settings directly to the [Conjur::Configuration](https://github.com/conjurinc/api-ruby/blob/master/lib/conjur/configuration.rb) 
object.

For example, specify the `account` and `appliance_url` (both of which are required) like this:

```
Conjur.configuration.account = 'my-account'
Conjur.configuration.appliance_url = 'https://conjur.mydomain.com/api'
```

You can also specify these values using environment variables, which is often a bit more convenient. 
Environment variables are mapped to configuration variables by prepending `CONJUR_` to the all-caps name of the 
configuration variable. For example, `appliance_url` is `CONJUR_APPLIANCE_URL`, `account` is `CONJUR_ACCOUNT`.

In either case, you will also need to configure certificate trust. For example:

```
OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.add_file "/etc/conjur-yourorg.pem"
```

Once Conjur is configured, you can create a new API client by providing a `login` and `api_key`:

```
Conjur::API.new_from_key login, api_key
```

Note that if you are connecting as a [Host](http://developer.conjur.net/reference/services/directory/host), the login should be 
prefixed with `host/`. For example: `host/myhost.example.com`, not just `myhost.example.com`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright 2016-2017 CyberArk

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this software except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
