# How To Create New node_utils APIs

#### Table of Contents

* [Overview](#overview)
* [Start here: Clone the Repo](#clone)
* [Basic Example: feature bash-shell](#simple)
 * [Step 1. YAML Definitions: feature bash-shell](#yaml)
 * [Step 2. Create the node_utils API: feature bash-shell](#api)
 * [Step 3. Create the Minitest: feature bash-shell](#minitest)
 * [Step 4. rubocop / lint: feature bash-shell](#lint)
* [Advanced Example: router eigrp](#complex)
 * [Step 1. YAML Definitions: router eigrp](#comp_yaml)
 * [Step 2. Create the node_utils API: router eigrp](#comp_api)
 * [Step 3. Create the Minitest: router eigrp](#comp_minitest)
 * [Step 4. rubocop / lint: router eigrp](#comp_lint)

## <a name="overview">Overview</a>

This document is a HowTo guide for writing new cisco node_utils APIs. The node_utils APIs act as an interface between the NX-OS CLI and an agent's resource/provider. If written properly the new API will work as a common framework for multiple providers (Puppet, Chef, etc).

There are multiple components involved when creating new resources. This document focuses on the cisco node_utils API, command reference YAML files, and minitests.

![1](agent_files.png)

## <a name="clone">Start here: Clone the Repo</a>

First install the code base. Clone the cisco_node_utils repo into a workspace:

```bash
git clone https://github.com/cisco/cisco-network-node-utils.git
```

## <a name="simple">Basic Example: feature bash-shell</a>

Writing a new node_utils API is often easier to understand through example code. The NX-OS CLI for `feature bash-shell` is a simple on / off style configuration and therefore a good candidate for a simple API:

`[no] feature bash-shell`

### <a name="yaml">Step 1. YAML Definitions: feature bash-shell</a>

The new API will need some basic YAML definitions. These are used with the `CommandReference` module as a way to abstract away platform CLI differences.

`command_reference_common.yaml` is used for settings that are common across all platforms while other files are used for settings that are unique to a given platform. Our `feature bash-shell` example uses the same cli syntax on all platforms, thus we only need to edit the common file:

`cisco_network_node_utils/lib/cisco_node_utils/command_reference_common.yaml`

Four basic command_reference parameters will be defined for each resource property:

 1. `config_get:` This defines the NX-OS CLI command (usually a 'show...' command) used to retrieve the property's current configuration state. Note that some commands may not be present until a feature is enabled.
 2. `config_get_token:` A regexp pattern for extracting state values from the config_get output.
 3. `config_set:` The NX-OS CLI configuration command(s) used to set the property configuration. May contain wildcards for variable parameters.
 4. `default_value:` This is typically the "factory" default state of the property, expressed as an actual value (true, 12, "off", etc)

There are additional YAML command parameters available which are not covered by this document. Please see the [README_YAML.md](../lib/cisco_node_utils/README_YAML.md) document for more information on the structure and semantics of these files.

#### Example: YAML Property Definitions for feature bash-shell

The `feature bash-shell` configuration is displayed with the `show running-config` command. Anchor the config_get_token regexp pattern carefully as it may match on unwanted configurations.

*Note: YAML syntax has strict indentation rules. Do not use TABs.*

```
bash_shell:
  feature:
    config_get: 'show running'                   # get current bash config state
    config_get_token: '/^feature bash-shell$/'   # Match only 'feature bash-shell'
    config_set: '<state> feature bash-shell'     # Config needed to enable/disable
```

### <a name="api">Step 2. cisco_node_utils API file: feature bash-shell</a>

* Before creating the new API, first add a new entry: `require "cisco_node_utils/bash_shell"`  to the master list of resources in:

```
cisco_network_node_utils/lib/cisco_node_utils.rb
```

* There are template files in /docs that may help when writing new APIs. These templates provide most of the necessary code with just a few customizations required for a new resource. Copy the `template-feature.rb` file to use as the basis for `bash_shell.rb`:

```bash
cp  docs/template-feature.rb  cisco_network_node_utils/bash_shell.rb
```

* Edit `bash_shell.rb` and substitute the placeholder text as shown here:

```bash
/X__CLASS_NAME__X/BashShell/

/X__RESOURCE_NAME__X/bash_shell/
```

#### Example: bash_shell.rb API

This is the completed bash_shell API based on `template-feature.rb`:

```ruby

require File.join(File.dirname(__FILE__), 'node')
module Cisco
# Class name syntax will typically be the resource name in camelCase
# format; for example: 'tacacs server host' becomes TacacsServerHost.
class BashShell
  # Establish connection to node
  @@node = Cisco::Node.instance

  def feature_enable
    @@node.config_set('bash_shell', 'feature', { :state => '' })
  end

  def feature_disable
    @@node.config_set('bash_shell', 'feature', { :state => 'no' })
  end

  # Check current state of the configuration
  def BashShell.feature_enabled
    feat =  @@node.config_get('bash_shell', 'feature')
    return (!feat.nil? and !feat.empty?)
  rescue Cisco::CliError => e
    # This cmd will syntax reject if feature is not
    # enabled. Just catch the reject and return false.
    return false if e.clierror =~ /Syntax error/
    raise
  end
end
end
```

### <a name="minitest">Step 3. Minitest: feature bash-shell</a>

* A minitest should be created to validate the new APIs. Minitests are stored in the tests directory: `cisco_network_node_utils/tests/`

* Tests may use `@device.cmd("show ...")` to access the CLI directly set up tests and validate expected outcomes. The tests directory contains many examples of how these are used.

* Our minitest will be very basic since the API itself is very basic. Use `template-test_feature.rb` to create a minitest for the bash_shell resource:

```bash
cp  docs/template-test_feature.rb  cisco_network_node_utils/tests/test_bash_shell.rb
```

* As with the API code, edit `test_bash_shell.rb` and change the placeholder names as shown:

```bash
/X__CLASS_NAME__X/BashShell/

/X__RESOURCE_NAME__X/bash_shell/

/X__CLI_NAME__X/bash-shell/
```

#### Example: test_bash_shell.rb

This is the completed `bash_shell` minitest based on `template-test_feature.rb`:

```ruby
#
# Minitest for BashShell class
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/bash_shell", __FILE__)

class TestBashShell < CiscoTestCase
  def setup
    # setup automatically runs at the beginning of each test
    super
    no_feature
  end

  def teardown
    # teardown automatically runs at the end of each test
    no_feature
    super
  end

  def no_feature
    # setup/teardown helper. Turn the feature off for a clean testbed.
    @device.cmd('conf t ; no feature bash-shell ; end')
    node.cache_flush()
  end

  def test_feature_on_off
    feat = BashShell.new()
    feat.feature_enable
    assert(BashShell.feature_enabled)

    feat.feature_disable
    refute(BashShell.feature_enabled)
  end

end
```


We can now run the new minitest against our NX-OS device using this syntax:

```bash
ruby test_bash_shell.rb -- <node_ip_address> <user> <passwd>
```
*Note. The minitest requires that the NX-OS device have 'feature nxapi' enabled. This will typically be enabled by default.*

#### Example: Running bash_shell minitest

```bash
% ruby  test_bash_shell.rb  -- 192.168.0.1 admin admin
Run options: -v -- --seed 23392

# Running tests:

CiscoTestCase#test_placeholder =
Ruby Version - 1.9.3
Node in CiscoTestCase Class: 192.168.0.1
Platform:
  - name  - my_n9k
  - type  - N9K-C9504
  - image - bootflash:///n9000-dk9.7.0.3.I2.0.509.bin

1.79 s = .
TestBashShell#test_feature_on_off = 1.42 s = .
TestBashShell#test_placeholder = 0.95 s = .
TestCase#test_placeholder = 0.81 s = .

Finished tests in 4.975186s, 0.8040 tests/s, 0.4020 assertions/s.

4 tests, 2 assertions, 0 failures, 0 errors, 0 skips
```

*Note. The minitest harness counts the helper methods as tests which is why the final tally shows 4 tests instead of just 2 tests.*

### <a name="lint">Step 4. rubocop / lint: feature bash-shell</a>

rubocop is a Ruby static analysis tool. Run rubocop with the --lint option to validate the new API:

```bash
% rubocop --lint bash_shell.rb
Inspecting 1 file
.

1 file inspected, no offenses detected
```

## <a name="complex">Advanced Example: router eigrp</a>

Now that we have a basic example working we can move on to a slightly more complex cli.
`router eigrp` requires feature enablement and supports multiple eigrp instances. It also has multiple configuration levels for vrf and address-family.

For the purposes of this example we will only implement the following properties:

```bash
[no] feature eigrp               (boolean)
[no] router eigrp [name]         (string)
       maximum-paths [n]         (integer)
       [no] shutdown             (boolean)

Example:
  feature eigrp
  router eigrp Blue
    maximum-paths 5
    shutdown
```

### <a name="comp_yaml">Step 1. YAML Definitions: router eigrp</a>

As with the earlier example, `router eigrp` will need YAML definitions in the common file:

`cisco_network_node_utils/lib/cisco_node_utils/command_reference_common.yaml`

The properties in this example require additional context for their config_get_token values because they need to differentiate between different eigrp instances. Most properties will also have a default value.

*Note: Eigrp also has vrf and address-family contexts. These contexts require additional coding and are beyond the scope of this document.*

#### Example: YAML Property Definitions for router eigrp

*Note: The basic token definitions for multi-level commands can become long and complicated. A better solution for these commands is to use a command_reference _template: definition to simplify the configuration. The example below will use the basic syntax; see the ospf definitions in the YAML file for an example of _template: usage.*

```yaml
eigrp:
  feature:
    # feature eigrp must be enabled before configuring router eigrp
    config_get: 'show running eigrp all'
    config_get_token: '/^feature eigrp$/'
    config_set: '<state> feature eigrp'

  router:
    # There can be multiple eigrp instances
    config_get: 'show running eigrp all'         # all eigrp-related configs
    config_get_token: '/^router eigrp (\S+)$/'   # Match instance name
    config_set: '<state> router eigrp <name>'    # config to add or remove

  maximum_paths:
    # This is an integer property
    config_get: 'show running eigrp all'
    config_get_token: ['/^router eigrp <name>$/', '/^maximum-paths (\d+)/']
    config_set: ['router eigrp <name>', 'maximum-paths <val>']
    default_value: 8

  shutdown:
    # This is a boolean property
    config_get: 'show running eigrp all'
    config_get_token: ['/^router eigrp <name>$/', '/^shutdown$/']
    config_set: ['router eigrp <name>', '<state> shutdown']
    default_value: false
```

### <a name="comp_api">Step 2. cisco_node_utils API: router eigrp</a>

* Add a new entry: `require "cisco_node_utils/router_eigrp"` to the master list in:

```
cisco_network_node_utils/lib/cisco_node_utils.rb
```

* The `template-router.rb` file provides a basic router API that we will use as the basis for `router_eigrp.rb`:

```bash
cp  docs/template-router.rb  cisco_network_node_utils/router_eigrp.rb
```

* Our new `router_eigrp.rb` requires changes from the original template. Edit `router_eigrp.rb` and change the placeholder names as shown.

```
/X__CLASS_NAME__X/RouterEigrp/

/X__RESOURCE_NAME__X/eigrp/

/X__PROPERTY_BOOL__X/shutdown/

/X__PROPERTY_INT__X/maximum_paths/
```

*Note that this template only provides example property methods for a few properties. Copy the example methods for additional properties as needed.*

#### Example: router_eigrp.rb
This is the completed `router_eigrp` API based on `template-router.rb`:

```ruby
#
# NXAPI implementation of RouterEigrp class
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.join(File.dirname(__FILE__), 'node')

module Cisco
class RouterEigrp
  attr_reader :name

  # Establish connection to node
  @@node = Cisco::Node.instance

  # name: name of the router instance
  # instantiate: true = create router instance
  def initialize(name, instantiate=true)
    raise ArgumentError unless name.length > 0
    @name = name
    create if instantiate
  end

  # Create a hash of all current router instances.
  def RouterEigrp.routers
    instances = @@node.config_get('eigrp', 'router')
    return {} if instances.nil?
    hash = {}
    instances.each do |name|
      hash[name] = RouterEigrp.new(name, false)
    end
    return hash
  rescue Cisco::CliError => e
    # cmd will syntax reject when feature is not enabled
    raise unless e.clierror =~ /Syntax error/
    return {}
  end

  def feature_enabled
    feat =  @@node.config_get('eigrp', 'feature')
    return (!feat.nil? and !feat.empty?)
  rescue Cisco::CliError => e
    # This cmd will syntax reject if feature is not
    # enabled. Just catch the reject and return false.
    return false if e.clierror =~ /Syntax error/
    raise
  end

  def feature_enable
    @@node.config_set('eigrp', 'feature', { :state => '' })
  end

  def feature_disable
    @@node.config_set('eigrp', 'feature', { :state => 'no' })
  end

  # Enable feature and create router instance
  def create
    feature_enable unless feature_enabled
    eigrp_router
  end

  # Destroy a router instance; disable feature on last instance
  def destroy
    ids = @@node.config_get('eigrp', 'router')
    return if ids.nil?
    if ids.size == 1
      feature_disable
    else
      eigrp_router('no')
    end
  rescue Cisco::CliError => e
    # cmd will syntax reject when feature is not enabled
    raise unless e.clierror =~ /Syntax error/
  end

  def eigrp_router(state='')
    @@node.config_set('eigrp', 'router', { :name => @name, :state => state })
  end

  # ----------
  # PROPERTIES
  # ----------

  # Property methods for boolean property
  def default_shutdown
    @@node.config_get_default('eigrp', 'shutdown')
  end

  def shutdown
    state = @@node.config_get('eigrp', 'shutdown', { :name => @name })
    state ? true : false
  end

  def shutdown=(state)
    state = (state ? '' : 'no')
    @@node.config_set('eigrp', 'shutdown', { :name => @name, :state => state })
  end

  # Property methods for integer property
  def default_maximum_paths
    @@node.config_get_default('eigrp', 'maximum_paths')
  end

  def maximum_paths
    val = @@node.config_get('eigrp', 'maximum_paths', { :name => @name })
    val.nil? ? default_maximum_paths : val.first.to_i
  end

  def maximum_paths=(val)
    @@node.config_set('eigrp', 'maximum_paths', { :name => @name, :val => val })
  end

end
end
```

### <a name="comp_minitest">Step 3. Minitest: router eigrp</a>

* Use `template-test_router.rb` to build the minitest for `router_eigrp.rb`:

```
cp  docs/template-test_router.rb  cisco_network_node_utils/tests/test_router_eigrp.rb
```
* As with the API code, edit `test_router_eigrp.rb` and change the placeholder names as shown:

```
/X__CLASS_NAME__X/RouterEigrp/

/X__RESOURCE_NAME__X/eigrp/

/X__PROPERTY_BOOL__X/shutdown/

/X__PROPERTY_INT__X/maximum_paths/
```

* At a minimum, the tests should include coverage for:
  * creating & destroying a single `router eigrp` instance
  * creating & destroying multiple `router eigrp` instances
  * feature disablement when removing last `router eigrp`
  * testing each property state

#### Example: test_router_eigrp.rb
This is the completed `test_router_eigrp` minitest based on `template-test_router.rb`:

```ruby
#
# Minitest for RouterEigrp class
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/router_eigrp", __FILE__)

class TestRouterEigrp < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_feature_eigrp
  end

  def teardown
    # teardown runs at the end of each test
    no_feature_eigrp
    super
  end

  def no_feature_eigrp
    # Turn the feature off for a clean test.
    @device.cmd("conf t ; no feature eigrp ; end")
    node.cache_flush()
  end

  # TESTS

  def test_router_create_destroy_one
    id = "blue"
    rtr = RouterEigrp.new(id)
    s = @device.cmd("show runn | i 'router eigrp #{id}'")
    assert_match(s, /^router eigrp #{id}$/,
                 "Error: failed to create router eigrp #{id}")

    rtr.destroy
    s = @device.cmd("show runn | i 'router eigrp #{id}'")
    refute_match(s, /^router eigrp #{id}$/,
                 "Error: failed to destroy router eigrp #{id}")

    s = @device.cmd("show runn | i 'feature eigrp'")
    refute_match(s, /^feature eigrp$/,
                 "Error: failed to disable feature eigrp")
  end

  def test_router_create_destroy_multiple
    id1 = "blue"
    rtr1 = RouterEigrp.new(id1)
    id2 = "red"
    rtr2 = RouterEigrp.new(id2)

    s = @device.cmd("show runn | i 'router eigrp'")
    assert_match(s, /^router eigrp #{id1}$/)
    assert_match(s, /^router eigrp #{id2}$/)

    rtr1.destroy
    s = @device.cmd("show runn | i 'router eigrp #{id1}'")
    refute_match(s, /^router eigrp #{id1}$/,
                 "Error: failed to destroy router eigrp #{id1}")

    rtr2.destroy
    s = @device.cmd("show runn | i 'router eigrp #{id2}'")
    refute_match(s, /^router eigrp #{id2}$/,
                 "Error: failed to destroy router eigrp #{id2}")

    s = @device.cmd("show runn | i 'feature eigrp'")
    refute_match(s, /^feature eigrp$/,
                 "Error: failed to disable feature eigrp")
  end

  def test_router_maximum_paths
    id = "blue"
    rtr = RouterEigrp.new(id)
    val = 5   # This value depends on property bounds
    rtr.maximum_paths = val
    assert_equal(rtr.maximum_paths, val, "maximum_paths is not #{val}")

    # Get default value from yaml
    val = node.config_get_default("eigrp", "maximum_paths")
    rtr.maximum_paths = val
    assert_equal(rtr.maximum_paths, val, "maximum_paths is not #{val}")
  end

  def test_router_shutdown
    id = "blue"
    rtr = RouterEigrp.new(id)
    rtr.shutdown = true
    assert(rtr.shutdown, "shutdown state is not true")

    rtr.shutdown = false
    refute(rtr.shutdown, "shutdown state is not false")
  end
end
```

Now run the test:

```bash
% ruby-1.9.3-p0 test_router_eigrp.rb -v -- 192.168.0.1 admin admin
Run options: -v -- --seed 56593

# Running tests:

CiscoTestCase#test_placeholder =
Ruby Version - 1.9.3
Node in CiscoTestCase Class: 192.168.0.1
Platform:
  - name  - my_n3k
  - type  - N3K-C3132Q-40GX
  - image -

2.90 s = .
TestCase#test_placeholder = 0.92 s = .
TestRouterEigrp#test_placeholder = 0.97 s = .
TestRouterEigrp#test_router_create_destroy_multiple = 10.77 s = .
TestRouterEigrp#test_router_create_destroy_one = 6.14 s = .
TestRouterEigrp#test_router_maximum_paths = 9.41 s = .
TestRouterEigrp#test_router_shutdown = 6.40 s = .


Finished tests in 37.512356s, 0.1866 tests/s, 0.3199 assertions/s.

7 tests, 12 assertions, 0 failures, 0 errors, 0 skips
```

### <a name="comp_lint">Step 4. rubocop / lint: router eigrp</a>

rubocop is a Ruby static analysis tool. Run rubocop with the --lint option to validate the new API:

```bash
% rubocop --lint router_eigrp.rb
Inspecting 1 file
.

1 file inspected, no offenses detected
```

## Conclusion

This was hopefully a good introduction to writing a Cisco node_utils API. At this point you could continue adding properties or try your hand at writing Puppet or Chef provider code to utilize your new API.
