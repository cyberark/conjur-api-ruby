Group#create
============

A group is created from an identifier. The identifier should be unique.

Example
-------

### Command Line

```bash
$ conjur group:create `conjur id:create`
Created https://core-sandbox-conjur.herokuapp.com/groups/5zjys0
```

### API

```ruby
conjur.create_group SecureRandom.uuid
```
