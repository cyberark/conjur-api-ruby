Role#memberships
================

List the roles that a role has been granted, transitively.

If role "A" is granted to role "B" which is granted to role "C", then the memberships of role "C" are [ "C", "B", "A" ].

Examples
--------

### Command Line

```bash
$ ns=`conjur id:create`
$ conjur role:create test:$ns/A
$ conjur role:create test:$ns/B
$ conjur role:create test:$ns/C
$ conjur role:grant_to test:$ns/A test:$ns/B
$ conjur role:grant_to test:$ns/B test:$ns/C
$ conjur role:memberships test:$ns/C
[
  "sandbox:test:dy7mg0/C",
  "sandbox:test:dy7mg0/B",
  "sandbox:test:dy7mg0/A"
]
```
