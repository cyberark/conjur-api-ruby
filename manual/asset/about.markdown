Asset
=====

Implements a domain-specific permission modeling concept. Assets combine functionality of roles, resources, and other assets
together into unified APIs.

Assets commonly perform the following functions:

* **containment** An asset can contain other assets, such as an environment which contains variables or a deployment which contains hosts.
Assets can be collected and re-combined arbitrarily.
* **role management** Container assets can define roles which manage permissions on child assets. 

