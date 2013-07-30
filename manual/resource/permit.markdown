Resource#permit
===============

Gives a specific permission on a resource to a role. 

Example
-------

### Command Line

```bash
$ conjur host:create
<snip>
$ conjur resource:permit food:bacon host:a4yta8 fry
Permission granted
$ conjur resource:check food:bacon host:a4yta8 fry
true
$ conjur resource:check food:bacon host:a4yta8 bake
false
$ conjur resource:permitted_roles food:bacon fry
[
  {
    "id": {
      "account": "sandbox",
      "id": "user:kgilpin"
    }
  },
  {
    "id": {
      "account": "sandbox",
      "id": "host:a4yta8"
    }
  }
]
```
