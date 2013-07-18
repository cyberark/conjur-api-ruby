Asset#members#add
=================

A common purpose of an asset is to manage access to a collection of "child" assets. Permissions on child assets are granted
via roles defined on the parent asset.

For example, consider an Environment asset which contains a number of child Variables:

```
Environment[e1]
  - variables
    - Variable[v1]
    - Variable[v2]
    - Variable[v3]
```

The Environment may define a role "use_variable" and permit "read" and "execute" on each variable by the "use_variable" role. 
Therefore, granting the "use_variable" role to another role "r1" will permit r1 to read and execute each variable.

Examples
--------

### Command Line

```bash
$ conjur asset:create environment `conjur id:create`
{
  "id": "9yxa80",
  <snip>
}
$ conjur host:create
{
  "id": "9bfqx5",
  <snip>
}
$ conjur environment:variables:create 9yxa80 test-var test text/plain "the-value"
Variable created
$ conjur asset:show environment 9yxa80
{
  "id": "9yxa80",
  "variables": {
    "test-var": "he2e00"
  },
  <snip>
}
$ conjur resource:check variable he2e00 host:9bfqx5 execute
false
$ conjur asset:members:add environment 9yxa80 use_variable host:9bfqx5
Membership granted
$ conjur resource:check variable he2e00 host:9bfqx5 execute
true
```
