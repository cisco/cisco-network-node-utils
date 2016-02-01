# How To Update node_utils APIs to Support XR

#### Table of Contents

* [Overview](#overview)
* [Run minitest on Nexus](#minitest-nexus)
* [Run minitest on XR](#minitest-xr)
* [Fix errors](#fix-errors)
 * [get_command differences](#get_command)
 * [get_value/set_value differences](#get_value)
 * [Unsupported attributes](#unsupported)
 * [Interface differences](#interface)
 * [Setup/teardown differences](#setup)
 * [Dependency differences](#dependency)
 * [Other differences](#other)

## <a name="overview">Overview</a>

This document is a HowTo guide for taking existing cisco_node_utils APIs written to work on Nexus, and enhancing them to support IOS XR. Please see [How To Create New node_utils APIs](./README-develop-node-utils-APIs.md) for setup steps.

Specifically, this will walk you through the general steps that were needed to enhance the bgp_neighbor feature to add XR support.  The changes detailed here are not the only changes that were made, but they should be representative of the kinds of changes that might be needed.

*Note: This document assumes you have a Nexus VM/device at 192.168.0.1 with user/password admin/admin, and an XR VM/device at 192.168.0.2 with user/password admin/admin and grpc port configured to 57777.*

## <a name="minitest-nexus">Run minitest on Nexus</a>

It's a good idea to make sure all the tests are running on Nexus before making any changes (just to be sure).  From the ./cisco_network_node_utils/tests directory:

```bash
% ruby test_bgp_neighbor.rb -v -- 192.168.0.1 admin admin
```

All tests should finish successfully (no failures, errors, or skips).

## <a name="minitest-xr">Run minitest on XR</a>

Now run the same tests against XR, to see what is broken and to get an idea of how much work will need to be done.

```bash
% ruby test_bgp_neighbor.rb -v -- 192.168.0.2:57777 admin admin
```

## <a name="fix-errors">Fix errors</a>

We'll now go through the types of differences that will cause errors/failures, and how to fix them.  When you've fixed a particular error, run minitest again on that single test ("`ruby test_bgp_neighbor.rb -n test_case_name_goes_here ...`") until it is working as you intend, then re-run the same test against Nexus to make sure it still works.

#### <a name="get_command">`get_command` differences</a>

The base `get_command` parameter will often be different on XR than Nexus.  Usually, the `get_command` is common across many attributes of a given feature, and therefore will be defined in the `_template` section.  In the case of the bgp neighbor feature, the `get_command` parameter to retrieve information about neighbors is "`show running bgp all`" on Nexus, while it is "`show running router bgp`" on XR.  This difference caused most/all of the `test_bgp_neighbor.rb` tests to error when run against XR, which looked something like this:

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

To correct this problem, the following changes were made in `bgp_neighbor.yaml`:

```yaml
  _template:
-   get_command: "show running router bgp"
+   ios_xr:
+     get_command: "show running router bgp"
+   nexus:
+     get_command: "show running bgp all"
    context:
      - "router bgp <asnum>"
      - "(?)vrf <vrf>"
      - "(?)neighbor <nbr>"
```

Here, the "global" get_command parameter was converted into two platform-specific parameters, while the context remained the same.

#### <a name="get_value">get\_value/set\_value differences</a>

Similar to the `get_command` differences above, the feature might have an attribute that is functionally equivalent on Nexus and XR, but have small syntactic differences.  An example of this for bgp neighbor is the `connected_check` attribute which produced the following error on XR:

```bash
  1) Error:
TestRouterBgpNeighbor#test_connected_check:
Cisco::CliError: CliError: '(unknown, see error message)' rejected with message:
'The command '(unknown, see error message)' was rejected with error:

Unable to process cmd, ret-val: 3, cmd: no router bgp 55 neighbor 1.1.1.1 disable-connected-check'
```

And required the following change in `bgp_neighbor.yaml`:

```yaml
  connected_check:
    auto_default: false
    kind: boolean
-   get_value: '/^disable-connected-check$/'
-   set_value: '<state> disable-connected-check'
+   ios_xr:
+     get_value: '/^ignore-connected-check$/'
+     set_value: '<state> ignore-connected-check'
+   nexus:
+     get_value: '/^disable-connected-check$/'
+     set_value: '<state> disable-connected-check'
    default_value: true
```

#### <a name="unsupported">Unsupported attributes</a>

Sometimes a Nexus command does not have an equivalent command on XR, and so the attribute will be considered unsupported on IOS XR.  An example of this is the bgp neighbor "`low-memory-exempt`" attribute which produced the now-familiar "unable to process cmd" error on XR.  The changes needed to mark this attribute as unsupported on XR are as follows:

First, we exclude the attribute in `bgp_neighbor.yaml`:

```yaml
  low_memory_exempt:
+   _exclude: [ios_xr]
    kind: boolean
    get_value: '/^low-memory exempt$/'
    set_value: '<state> low-memory exempt'
    default_value: false
```

This will cause any calls to config_set for this attribute to raise a `Cisco::UnsupportedError`, and calls to `config_get` and `config_get_default` will return `nil`.  Because of this, we must update the `test_bgp_neighbor.rb` minitest to expect these conditions on XR (see [Development Best Practices: MT6](./README-develop-best-practices.md#mt6)):

```ruby
  def test_low_memory_exempt
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
+     if platform == :ios_xr
+       assert_nil(neighbor.low_memory_exempt)
+       assert_nil(neighbor.default_low_memory_exempt)
+       assert_raises(Cisco::UnsupportedError) do
+         neighbor.low_memory_exempt = true
+       end
+     else
        check = [true, false, neighbor.default_low_memory_exempt]
        check.each do |value|
          neighbor.low_memory_exempt = value
          assert_equal(value, neighbor.low_memory_exempt)
        end
+     end
      neighbor.destroy
    end
  end
```

#### <a name="interface">Interface differences</a>

The interfaces available for use on XR will be different than Nexus, so any existing tests that refer to interfaces by name will likely fail on XR.  Here is the error from the update-source test:

```bash
  1) Error:
TestRouterBgpNeighbor#test_update_source:
Cisco::CliError: CliError: '(unknown, see error message)' rejected with message:
'The command '(unknown, see error message)' was rejected with error:

Unable to process cmd, ret-val: 3, cmd: router bgp 55 neighbor 1.1.1.1  update-source Ethernet1/1'
```

From the error, you can't tell which part of the command was rejected, so you might initially think that update-source is not supported on XR.  Typing the command directly into the XR CLI will give a better idea of what specifically is wrong.

```bash
RP/0/RP0/CPU0:agent-lab20-xr#conf
Fri Jan 29 14:02:50.566 UTC
RP/0/RP0/CPU0:agent-lab20-xr(config)#router bgp 55 neighbor 1.1.1.1  update-source Ethernet1/1
                                                                                   ^
% Invalid input detected at '^' marker.
```

As you can see in CLI output, the '^' marker is indicating that "Ethernet1/1" is invalid.  Instead of using hardcoded interface names, use the `interfaces[]` array (see [Development Best Practices: MT3](./README-develop-best-practices.md#mt3)).

```ruby
  def test_update_source
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
-     test_interfaces = ['loopback1', 'Ethernet1/1', 'ethernet1/1',
+     test_interfaces = ['loopback1', interfaces[0], interfaces[0].downcase,
                         neighbor.default_update_source]
      test_interfaces.each do |interface|
        neighbor.update_source = interface
        assert_equal(interface.downcase, neighbor.update_source)
      end
      neighbor.destroy
    end
  end
```

#### <a name="setup">Setup/teardown differences</a>

Your minitest's setup method is run before each test, and the teardown method is run after each test.  These methods often contain calls to the `TestCase.config` method to execute commands to clear existing configuration on the device, and often, the commands will differ between platforms. Currently, the `config` method does not display the output from executed commands, even when debug is enabled, so any errors that occur will be masked.

You should verify that any existing config commands are valid for XR (either by sight, or by executing them manually on the XR CLI).  The following changes were needed for `test_bgp_neighbor.rb`:

```ruby
  def setup
    # Disable feature bgp before each test to ensure we
    # are starting with a clean slate for each test.
    super
+   if platform == :ios_xr
+     config('no router bgp', 'router bgp 55')
+   else
      config('no feature bgp', 'feature bgp', 'router bgp 55')
+   end
  end

  def teardown
+   if platform == :ios_xr
+     config('no router bgp')
+   else
      config('no feature bgp')
+   end
  end
```

#### <a name="dependency">Dependency differences</a>

While enhancing the Cisco BGP features to support IOS XR, we found that configuring some attributes would require that other attributes be configured in a certain way, first (sometimes in the same sub-mode, sometimes in a parent mode).  Usually, we were able to solve this by creating helper methods in the minitests to set up any dependencies.

As an example, XR requires the bgp neighbor remote-as attribute to be set before any other neighbor attribute can be set.  Attempting to set the description on a neighbor without first setting the remote-as results in the following error:

```bash
  1) Error:
TestRouterBgpNeighbor#test_bgpneighbor_set_get_description:
Cisco::CliError: CliError: '(unknown, see error message)' rejected with message:
'The command '(unknown, see error message)' was rejected with error:
'BGP' detected the 'warning' condition 'Neighbor does not exist (ie has no remote-as defined) - create first''
```
The key part of this message is "(ie has no remote-as defined)".  To address this, we added a `create_neighbor` helper method in `test_bgp_neighbor.rb` which creates a neighbor and also configures any dependencies (in this case, it simply sets the remote-as):

```ruby
+ # Creates a neighbor to use in tests.
+ def create_neighbor(vrf, addr=ADDR)
+   neighbor = RouterBgpNeighbor.new(ASN, vrf, addr)
+
+   # XR requires a remote_as in order to set other properties
+   # (description, password, etc.)
+   neighbor.remote_as = REMOTE_ASN
+   neighbor
+ end

	:

  def test_bgpneighbor_set_get_description
    %w(default test_vrf).each do |vrf|
-     neighbor = RouterBgpNeighbor.new(ASN, vrf, ADDR)
+     neighbor = create_neighbor(vrf)
      description = "tested by mini test for vrf #{vrf}"
      neighbor.description = description
      assert_equal(description, neighbor.description)
      neighbor.description = ' '
      assert(neighbor.description.empty?)
      neighbor.description = neighbor.default_description
      assert_equal(neighbor.description, neighbor.default_description)
      neighbor.destroy
    end
  end
```

Other examples of BGP dependency issues we ran into on XR that did not exist on Nexus:

 - To configure an address family, we first needed to set the bgp router-id
 - To configure an address family under a vrf, we first needed to set the rd for that vrf

#### <a name="other">Other differences</a>

Each feature will be different, so it there will almost certainly be unique changes needed to support XR for a particular feature.  For bgp neighbor, that included the following:

 - XR does not support bgp neighbor addresses in the prefix/len format ("2.2.2.2/24"), so we had to skip those in the minitest on XR.
 - XR only supports a single encryption type for the password attribute (simply specified as "encrypted", which is actually "md5").  We updated the node_utils API to fail with a `Cisco::UnsupportedError` if an encryption type other than md5 is specified on XR (and updated the minitest to match).
 - XR supports three transport connection modes (active-only, passive-only, both), while Nexus only supports two (passive-only, both) through the `transport_passive_only` attribute.  We added a new `transport_passive_mode` attribute that accepts all three types.


## Conclusion

This was hopefully a good overview for updating an existing Cisco node_utils API to support IOS XR. It is not intended to cover every possible case, but might be updated in the future with other common cases.