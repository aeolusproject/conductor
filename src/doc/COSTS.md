Costs Engine
============

Summary
-------
This document explains the design of a cost estimation module for Aeolus
Conductor.

Owner
-----
Martin Povolny

Current Status
--------------

Implemented:

  * assigning costs to hardware profiles
  * assigning costs to hardware profile properties (memory, cpu, storage)
  * cost-based provider selection strategy with configuration

Implemented Use Cases
---------------------

* As an administrator, I want to assign costs to a provider's hardware
  profiles.
* As a user, I want to see costs for my running instances and deployables, and
  for instances and deployables which have run previously.
* As a manager I want Conductor to select providers based on cost estimates.

Future usecases:
* As an administrator I want Conductor to automaticaly download costs from
  providers.
* As a manager, I want to see costs for all users' running instances and
  deployables, and for instances and deployables which have run previously
* As an administrator, I want to see costs of running a deployable on available
  providers.

Design
------

Costs are associated with various 'chargeables'.

Chargeables include in the first run only:
  * a hour of run of given backend hardware profile.
  * a hour of run of given hardware profile properties (memory, cpu, storage)

Chargeables could include in the future:
  * unit of usage of bandwidth,
  * unit of usage of external storage,
  * unit of usage of IP assignment,
  * backups, load balancers, dababase access,
  * etc.

Each cost is associated with a chargeable (chargeable_id) of certain type
(chargeable_type).

And is valid at a certain time (valid_from, valid_to).

Unlimited validity is expressed by assiging NULL to valid_to.

Through the chargeable each cost is attached to a hardware profile and certain
provider.

For now cost-related modes methods are in a separate file
lib/costengine/mixins.rb and are included as mixins.

Placement in the UI
-------------------

* display cost information: /instances/1, /deployments/1 (properties tab)

* set hardware profile (properties) costs: /hardware_profiles/1 -->
  /costs/13/edit/costs, /1/edit_billing

* provider selection:
  /pools/1/provider_selection, /pools/1/provider_selection/cost_order/edit
