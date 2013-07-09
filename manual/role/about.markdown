Role
====

A role is a target to which permissions are assigned. Permitting an action on a resource by a role enables the role to perform
the specified action.

In addition, roles can be "granted to" other roles. When role "A" is granted to role "B", role "B" gains the ability to perform
all the actions permitted to "A". In addition, a role can be granted with "grant option". When role "A" is granted to role "B" with
grant option, role "B" can in turn grant role "A" to other roles.

