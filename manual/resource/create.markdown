Resource#create
===============

A resource is composed of a `kind` and `identifier`. The `kind`
indicates the semantic purpose of the resource, the identifier identifies
it uniquely within the kind. 

Example
-------

### Command Line

```bash
$ conjur resource:create food:bacon
{
  "id": {
    "account": "sandbox",
    "kind": "food",
    "id": "bacon"
  },
  "owner": {
    "account": "sandbox",
    "id": "user:kgilpin"
  },
  "permissions": [

  ]
}
```
