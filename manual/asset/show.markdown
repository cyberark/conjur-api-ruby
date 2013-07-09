Asset#show
==========

Display an asset as JSON.

The Conjur `jsonfield` utility can be used to pluck JSON values.

Examples
--------

### Command Line

#### Create and show an environment

```bash
$ id=`conjur id:create`
$ e=`conjur asset:create environment $id`
$ conjur asset:show environment id
{
  "id": "0y3s00",
  "variables": {
  },
  "userid": "kgilpin",
  "ownerid": "sandbox:user:kgilpin",
  "resource_identifier": "sandbox:environment:0y3s00"
}
```
#### Create and show a host

```bash
$ hostid=`conjur host:create | jsonfield id`
$ conjur asset:show host $hostid
{
  "id": "g7hytz",
  "userid": "kgilpin",
  "created_at": "2013-07-09T21:10:06+00:00",
  "ownerid": "sandbox:user:kgilpin",
  "roleid": "sandbox:host:g7hytz",
  "resource_identifier": "sandbox:host:g7hytz"
}
```

#### Attempt to show a non-existant asset.

```bash
$ conjur asset:show host foo
error: 404 Resource Not Found
$ echo $?
1
```