Host
====

A host represents a non-human user. VMs, processes, and jobs are all commonly represented as Hosts.

Attributes
----------

* **username** the host username is composed of the word 'host' composed with the host identifier. For example, "host/i-bbe231db"
* **api_key** each host is assigned an API key, just like a human user

Like a human User, a Host can authenticate with Conjur and perform actions.

Roles
-----

On creation, the host creates a Conjur role to represent itself. The role kind is 'host'.

Resources
---------

On creation, the host creates a Conjur resource to represent itself. 

