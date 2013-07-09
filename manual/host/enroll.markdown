Host#enroll
===========

Returns a unique URL which, when fetched, returns a shell command which will login
the host with Conjur.

Example
-------

```bash
$ conjur host:enroll vaz7qg
https://core-sandbox-conjur.herokuapp.com/hosts/enroll?key=7fxt_HiRfOodA3J6wh5s2X9a6gm-b-wkPmF0g-HOPYo=
On the target host, please execute the following command:
curl -L https://core-sandbox-conjur.herokuapp.com/hosts/enroll?key=7fxt_HiRfOodA3J6wh5s2X9a6gm-b-wkPmF0g-HOPYo= | bash
$ curl -L https://core-sandbox-conjur.herokuapp.com/hosts/enroll?key=7fxt_HiRfOodA3J6wh5s2X9a6gm-b-wkPmF0g-HOPYo=
#!/bin/sh
set -e

conjur authn:login -u host/vaz7qg -p 39c63b3d5bc372de1c100feec852e05f747bc9eb
```

