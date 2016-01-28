# How To Create New node_utils APIs

#### Table of Contents

* [Overview](#overview)
* [Before You Begin](#prerequisites)
* [Start here: Fork and Clone the Repo](#clone)
* [Example: router eigrp](#complex)
 * [Step 1. YAML Definitions: router eigrp](#comp_yaml)
 * [Step 2. Create the node_utils API: router eigrp](#comp_api)
 * [Step 3. Create the Minitest: router eigrp](#comp_minitest)
 * [Step 4. rubocop / lint: router eigrp](#comp_lint)
 * [Step 5. Build and Install the gem](#comp_gem)

## <a name="overview">Overview</a>

This document is a HowTo guide for taking existing cisco_node_utils APIs written to work on Nexus, and enhancing them to support IOS XR. Please see [How To Create New node_utils APIs](./README-develop-node-utils-APIs.md) for setup steps.

Specifically, this will walk you through the general steps that were needed to enhance the bgp_neighbor feature to add XR support.  The changes detailed here are not the only changes that were made, but they should be representative of the kinds of changes that need to be made.

This document assumes you have a Nexus VM at 192.168.0.1 with user/password admin/admin, and an XR VM at 192.168.0.2 with user/password admin/admin and grpc port configured to 57777.

## <a name="minitest-nexus">Start here: Run minitest on Nexus</a>

It's a good idea to make sure all the tests are running on Nexus before making any changes (just to be sure).  From ./cisco_network_node_utils/tests:

```bash
% ruby test_bgp_neighbor.rb -v -- 192.168.0.1 admin admin
```

All tests should finish successfully (no failures, errors, or skips).

## <a name="minitest-xr">Run minitest on XR</a>

Now run the same tests against XR, to see what is broken and to get an idea of how much work will need to be done.

```bash
% ruby test_bgp_neighbor.rb -v -- 192.168.0.2:57777 admin admin
```

We'll now go through the types of errors/failures you will see, and how to fix them.  When you've fixed a particular error, run minitest again on that single test until it is working as you intend, then re-run the same test against Nexus to make sure it still works.

## <a name="template">Base get_command parameter</a>

The base get_command parameter will often be different on XR than Nexus.  Usually, the get_command is common across many attributes of a given feature, and will be defined in the _template section.  In the case of the bgp neighbor feature, the get_command parameter to retrieve information about neighbors is "show running bgp all" on Nexus, while it is "show running router bgp" on XR.  This difference caused most/all of the test_bgp_neighbor.rb tests to error when run against XR, which looked something like this:

```bash
  1) Error:
TestRouterBgpNeighbor#test_timers:
Cisco::CliError: CliError: 'show running bgp all' rejected with message:
'The command 'show running bgp all' was rejected with error:

>>>show-cmd: show running bgp all <<<
show running bgp all
              ^
% Invalid input detected at '^' marker.'
```

To correct this problem, the following changes were made in bgp_neighbor.yaml:

```
_template:
-  get_command: "show running router bgp"
+  ios_xr:
+    get_command: "show running router bgp"
+  nexus:
+    get_command: "show running bgp all"
   context:
     - "router bgp <asnum>"
     - "(?)vrf <vrf>"
     - "(?)neighbor <nbr>"
```

The "global" get_command parameter was converted into two platform-specific parameters, while the context remained the same.

## <a name="template">Base get_command parameter</a>





## Conclusion

This was hopefully a good introduction to writing a Cisco node_utils API. At this point you could continue adding properties or try your hand at writing Puppet or Chef provider code to utilize your new API.
