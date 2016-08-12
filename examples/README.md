# Setup

Use the `start.sh` script to create the container environment. Once you're the `client` container, move to the `/app` directory and `bundle`.

```sh-session
$ ./start.sh
+ docker-compose build
...
root@c17b1fcef672:/# cd app/
root@c17b1fcef672:/app# bundle
Fetching gem metadata from https://rubygems.org/
...
root@c17b1fcef672:/app# 
```

Use `stop.sh` to delete the containers.

# Interactive usage

Start an interactive Ruby console, and login as the admin user:

```sh-session
root@c17b1fcef672:/app# bundle exec irb
irb(main):001:0> require 'possum'
=> true
irb(main):002:0> client = Possum::Client.new url: "http://conjur"
=> #<Possum::Client:0x007f8cf75e5610 @options={:url=>"http://conjur"}>
irb(main):003:0> api_key = client.login 'example', 'admin', 'secret'
=> "33ewq0h12dr4yd2ct6egs2480dmv1v25tvg3k6gh5v6hq8v01jxj079"
```

