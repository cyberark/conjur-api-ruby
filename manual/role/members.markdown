Role#members
============

Lists the roles that have been the recipient of a role grant. The creator of the role is always a role member.

If role "A" is created by user "U" and then granted to roles "B" and "C", then the members of role "A" are [ "U", "B", "C" ].

Examples
--------

### Command Line

#### Add a role member and list the members

```bash
$ conjur role:create test:`conjur id:create`
Created https://authz-v3-conjur.herokuapp.com/sandbox/roles/test/2y1300
$ conjur role:members test:2y1300
[
  "sandbox:user:kgilpin"
]
$ conjur host:create
{
  "id": "w43699",
  <snip>
}
$ conjur role:grant_to test:2y1300 host:w43699
Role granted
$ conjur role:members test:2y1300
[
  "sandbox:user:kgilpin",
  "sandbox:host:w43699"
]
```

#### The role argument is optional and defaults to the current role

```bash
$ conjur role:members
```