# Develoment Best Practices for cisco_node_utils APIs.

* [Overview](#overview)
* [YAML Development Best Practices](#ydbp)
* [Common Object Development Best Practices](#odbp)
* [MiniTest Development Best Practices](#mdbp)

## <a name="overview">Overview</a>

This document is intended to assist in developing cisco_node_utils API's that are consistent with current best practices.


## <a name="ydbp">YAML Development Best Practices</a>

* [Y1](#yaml1): One feature per YAML file
* [Y2](#yaml2): All attribute entries must be kept in alphabetical order.
* [Y3](#yaml3): Use *regexp* anchors where needed for CLI `get_context` and `get_value` entries.
* [Y4](#yaml4): Avoid nested optional matches.
* [Y5](#yaml5): Use the `_template` feature when getting/setting the same property value at multiple levels.
* [Y6](#yaml6): When possible include a `default_value` that represents the system default value.
* [Y7](#yaml7): When possible, use the same `get_command` for all properties and document any anomalies.
* [Y8](#yaml8): Use Key-value wildcards instead of Printf-style wildcards.
* [Y9](#yaml9): Selection of `show` commands for `get_command`.
* [Y10](#yaml10): Use `true` and `false` for boolean values.
* [Y11](#yaml11): Use YAML anchors and aliases to avoid redundant entries.
* [Y12](#yaml12): Use `_exclude` to return `nil` for unsupported properties.

## <a name="odbp">Common Object Development Best Practices</a>

* [CO1](#co1): Features that can be configured under the global and non-global vrfs need to account for this in the object design.
* [CO2](#co2): Make use of the equality operator allowing proper `instance1 == instance2` checks in the minitests.
* [CO3](#co3): Use `''` rather than `nil` to represent "property is absent entirely"
* [CO4](#co4): Make sure all new properties have a `getter`, `setter` and `default_getter` method.
* [CO5](#co5): Use singleton-like design for resources that cannot have multiple instances.
* [CO6](#co6): Implement a meaningful `to_s` method

## <a name="mdbp">MiniTest Development Best Practices</a>

* [MT1](#mt1): Ensure that **all new API's** have minitest coverage.
* [MT2](#mt2): Use appropriate `assert_foo` and `refute_foo` statements rather than `assert_equal`.
* [MT3](#mt3): Do not hardcode interface names.
* [MT4](#mt4): Make use of the `config` helper method for device configuration instead of `@device.cmd`.
* [MT5](#mt5): Make use of the `assert_show_match` and `refute_show_match` helper methods to validate expected outcomes in the CLI instead of `@device.cmd("show...")`.
* [MT6](#mt6): Unsupported properties must include negative test cases.


## YAML Best Practices:

### <a name="yaml1">Y1: One feature per YAML file

Each YAML file should define a single 'feature' (a closely related set of configuration properties). Don't create "one YAML file to rule them all".

### <a name="yaml2">Y2: All attribute entries must be kept in alphabetical order.

All attribute entries in a given YAML file must be kept in alphabetical order. As YAML permits duplicate entries (in which case the last entry overrides any earlier entries), keeping a consistent order helps to prevent accidentally introducing such duplication.

This rule is enforced by the `Cisco::CommandReference` class itself - it will raise an exception if it detects any out-of-order entries.

### <a name="yaml3">Y3: Use *regexp* anchors where needed for CLI `get_context` and `get_value` entries.

By default, CLI clients assume that `get_context` and `get_value` are to be treated as Regexps, and implicitly add regexp anchors and case-insensitivity (i.e., a `get_value` of `'router bgp 100'` becomes the regexp `/^router bgp 100$/i`). If you want to explicitly specify a regexp (perhaps because the default behavior does not meet your needs for a specific property), be sure to add the `^` and `$` anchors to ensure you match the correct feature information in the `show` output and do not unexpectedly match similar but undesired CLI strings.

```yaml
# syslog_settings.yaml
timestamp:
  get_command: "show running-config all | include '^logging timestamp'"
  get_value: 'logging timestamp (.*)'
  # this is equivalent to:
  # get_value: '/^logging timestamp (.*)$/'
  set_value: '<state> logging timestamp <units>'
  default_value: 'seconds'
```

### <a name="yaml4">Y4: Avoid nested optional matches.

Regexps containing optional match strings inside other match strings become
complex to work with and difficult to maintain.

One case where this may crop up is in trying to match both affirmative and
negative variants of a config command:

```yaml
get_context: ['interface <name>']
get_value: '((no )?switchport)'

get_value: '(no)? ?ip tacacs source-interface ?(\S+)?'
```

Instead, match the affirmative form of a command and treat its absence as
confirmation of the negative form:

```yaml
get_context: ['interface <name>']
get_value: 'switchport'

get_value: 'tacacs-server source-interface (\S+)'
```

### <a name="yaml5">Y5: Use the `_template` feature when getting/setting the same property value at multiple levels.

Using the template below, `auto_cost` and `default_metric` can be set under `router ospf foo` and `router ospf foo; vrf blue`.

```yaml
# ospf.yaml
_template:
  get_command: "show running ospf all"
  context:
    - 'router ospf <name>'
    - '(?)vrf <vrf>'

auto_cost:
  get_value: 'auto-cost reference-bandwidth (\d+)\s*(\S+)?'
  set_value: "auto-cost reference-bandwidth <cost> <type>"
  default_value: [40, "Gbps"]

default_metric:
  get_value: 'default-metric (\d+)?'
  set_value: "<state> default-metric <metric>"
  default_value: 0
```

### <a name="yaml6">Y6: When possible include a `default_value` that represents the system default value.

Please make sure to specify a `default_value` and document properties that don't have a system default.  System defaults may differ between cisco platforms making it important to define for lookup in the cisco_node_utils common object methods.


Default value for `message_digest_alg_type` is `md5`

```yaml
message_digest_alg_type:
  get_command: 'show running interface all'
  get_context: 'interface <name>'
  get_value: '/^\s*ip ospf message-digest-key \d+ (\S+)/'
  default_value: 'md5'
```

**NOTE1: Use strings rather then symbols when applicable**.

If the `default_value` differs between cisco platforms, use per-API or per-platform keys in the YAML as needed. For example, if the default value on all platforms except the N9k is `md5` then you might do something like this:

```yaml
message_digest_alg_type:
  get_command: 'show running interface all'
  get_context: 'interface <name>'
  get_value: '/^\s*ip ospf message-digest-key \d+ (\S+)/'
  N9k:
    default_value: 'sha2'
  else:
    default_value: 'md5'
```

See [README_YAML](../lib/cisco_node_utils/cmd_ref/README_YAML.md) for more details about this advanced feature.

### <a name="yaml7">Y7: When possible, use the same `get_command` for all properties and document any anomalies.

All properties below use the `show run tacacs all` command except `directed_request` which is documented.

```yaml
# tacacs_server.yaml
_template:
  get_command: "show run tacacs all"

deadtime:
  get_value: '/^tacacs-server deadtime\s+(\d+)/'
  set_value: "<state> tacacs-server deadtime <time>"
  default_value: 0

directed_request:
  # oddly, directed request must be retrieved from aaa output
  get_command: "show running aaa all"
  get_value: '/(?:no)?\s*tacacs-server directed-request/'
  set_value: "<state> tacacs-server directed-request"
  default_value: false

encryption_type:
  get_value: '/^tacacs-server key (\d+)\s+(\S+)/'
  default_value: 0

encryption_password:
  get_value: '/^tacacs-server key (\d+)\s+(\S+)/'
  default_value: ""
```

### <a name="yaml8">Y8: Use Key-value wildcards instead of Printf-style wildcards.

Key-value wildcards are moderately more complex to implement than Printf-style wildcards but they are more readable in the Ruby code and are flexible enough to handle significant platform differences in CLI. Key-value wildcards are therefore the recommended approach for new development.

**Key-value wildcards**

```yaml
get_value: "<state> log-adjacency-changes <type>"
```

This following approach is quick to implement and concise, but less flexible - in particular it cannot handle a case where different platforms take parameters in a different order - and less readable in the ruby code.

**Printf-style wildcards**

```yaml
get_value: "%s log-adjacency-changes %s"
```

### <a name="yaml9">Y9: Selection of `show` commands for `get_command`.

The following commands should be preferred over `show [feature]` commands since not all `show [feature]` commands behave in the same manner across cisco platforms.

* `show running [feature] all` if available.
* `show running all` if `show running [feature] all` is *not* available.

### <a name="yaml10">Y10: Use `true` and `false` for boolean values.

YAML allows various synonyms for `true` and `false` such as `yes` and `no`, but for consistency and readability (especially to users more familiar with Ruby than with YAML), we recommend using `true` and `false` rather than any of their synonyms.

### <a name="yaml11">Y11: Use YAML anchors and aliases to avoid redundant entries.

Use the standard YAML functionality of [node anchors](http://www.yaml.org/spec/1.2/spec.html#id2785586) and [node aliases](http://www.yaml.org/spec/1.2/spec.html#id2786196) to avoid redundant entries. In other words, instead of:

```yaml
  vn_segment_vlan_based:
   # MT-lite only
   N3k:
     kind: boolean
     config_get: 'show running section feature'
     config_get_token: '/^feature vn-segment-vlan-based$/'
     config_set: 'feature vn-segment-vlan-based'
     default_value: false
   N9k:
     # same as N3k
     kind: boolean
     config_get: 'show running section feature'
     config_get_token: '/^feature vn-segment-vlan-based$/'
     config_set: 'feature vn-segment-vlan-based'
     default_value: false
```

instead you can do:

```yaml
  vn_segment_vlan_based:
   # MT-lite only
   N3k: &vn_segment_vlan_based_mt_lite
     kind: boolean
     config_get: 'show running section feature'
     config_get_token: '/^feature vn-segment-vlan-based$/'
     config_set: 'feature vn-segment-vlan-based'
     default_value: false
   N9k: *vn_segment_vlan_based_mt_lite
```

### <a name="yaml12">Y12: Use `_exclude` to return `nil` for unsupported properties.

Some properties are only applicable to specific platforms. Rather than using `default_only` to specify an 'unconfigured' default like `''` or `false`, it is more accurate to return `nil` for a property that is not applicable at all. By returning `nil`, the property will not even appear in commands like `puppet resource`, which is the desired outcome.

Rather than specifying `default_only: nil`, the most straightforward and self-evident way to mark a property as unsupported is to use the `_exclude: [my_platform]` YAML tag. See [README_YAML.md](../lib/cisco_node_utils/cmd_ref/README_YAML.md#_exclude) for more details about the `_exclude` tag.

## Common Object Best Practices:

### <a name="co1">CO1: Features that can be configured under the global and non-global vrfs need to account for this in the object design.

Many cisco features can be configured under the default or global vrf and also under *n* number of non-default vrfs.

The following `initialize` and `self.vrfs` methods account for configuration under `default` and `non-default vrfs`.

```ruby
    def initialize(router, name, instantiate=true)
      fail TypeError if router.nil?
      fail TypeError if name.nil?
      fail ArgumentError unless router.length > 0
      fail ArgumentError unless name.length > 0
      @router = router
      @name = name
      @parent = {}
      if @name == 'default'
        @get_args = @set_args = { name: @router }
      else
        @get_args = @set_args = { name: @router, vrf: @name }
      end

      create if instantiate
    end

    # Create a hash of all router ospf vrf instances
    def self.vrfs
      hash_final = {}
      RouterOspf.routers.each do |instance|
        name = instance[0]
        vrf_ids = config_get('ospf', 'vrf', name: name)
        hash_tmp = { name =>
          { 'default' => RouterOspfVrf.new(name, 'default', false) } }
        unless vrf_ids.nil?
          vrf_ids.each do |vrf|
            hash_tmp[name][vrf] = RouterOspfVrf.new(name, vrf, false)
          end
        end
        hash_final.merge!(hash_tmp)
      end
      hash_final
    end
```

### <a name="co2">CO2: Make use of the equality operator allowing proper `instance1 == instance2` checks in the minitests.

Having this logic defined in the common object lets the minitest easily check the specific instances.

The built-in equality operator `==` returns true only if they are the same instance object. The `==` method below is used to override the built-in equality operator and return true even if they are different objects referring to the same configuration on the node.

```ruby
  def ==(other)
    (name == other.name) && (vrf == other.vrf)
  end
```

Example Usage:

```ruby
  def test_dnsdomain_create_destroy_multiple
    id1 = 'aoeu.com'
    id2 = 'asdf.com'
    refute_includes(Cisco::DnsDomain.dnsdomains, id1)
    refute_includes(Cisco::DnsDomain.dnsdomains, id2)

    ns1 = Cisco::DnsDomain.new(id1)
    ns2 = Cisco::DnsDomain.new(id2)
    assert_includes(Cisco::DnsDomain.dnsdomains, id1)
    assert_includes(Cisco::DnsDomain.dnsdomains, id2)
    assert_equal(Cisco::DnsDomain.dnsdomains[id1], ns1)
    assert_equal(Cisco::DnsDomain.dnsdomains[id2], ns2)

    ns1.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains, id1)
    assert_includes(Cisco::DnsDomain.dnsdomains, id2)
    ns2.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains, id2)
  end
```
### <a name="co3">CO3: Use `''` rather than `nil` to represent "property is absent entirely"

Our convention is to let `''` represent 'not configured at all' rather than `nil`. For example, `interface.rb`:

```ruby
def vrf
  vrf = config_get('interface', 'vrf', @name)
  return '' if vrf.nil?
  vrf.shift.strip
end

def vrf=(vrf)
  fail TypeError unless vrf.is_a?(String)
  if vrf.empty?
    config_set('interface', 'vrf', @name, 'no', '')
  else
    config_set('interface', 'vrf', @name, '', vrf)
  end
```

However, if a property has a default value (it is never truly 'removed'), then we should do this instead:

```ruby
def access_vlan
  vlan = config_get('interface', 'access_vlan', @name)
  return default_access_vlan if vlan.nil?
  vlan.shift.to_i
end

def access_vlan=(vlan)
  config_set('interface', 'access_vlan', @name, vlan)
```

### <a name="co4">CO4: Make sure all new properties have a `getter`, `setter` and `default_getter` method.

In order to have a complete set of api's for each property it is important that all properties have a `getter`, `setter` and `default_getter` method.

This can be seen in the following `router_id` property.

```ruby
# Getter Method
def router_id
  match = config_get('ospf', 'router_id', @get_args)
  match.nil? ? default_router_id : match.first
end

# Setter Method
def router_id=(router_id)
  if router_id == default_router_id
    @set_args[:state] = 'no'
    @set_args[:router_id] = ''
  else
    @set_args[:state] = ''
    @set_args[:router_id] = router_id
  end

  config_set('ospf', 'router_id', @set_args)
  delete_set_args_keys([:state, :router_id])
end

# Default Getter Method
def default_router_id
  config_get_default('ospf', 'router_id')
end
```

### <a name="co5">CO5: Use singleton-like design for resources that cannot have multiple instances.

See [TacacsServer](../lib/cisco_node_utils/tacacs_server.rb) and [SnmpServer](../lib/cisco_node_utils/snmpserver.rb) for examples.

### <a name="co6">CO6: Implement a meaningful `to_s` method

Request errors generated by a `NodeUtil` subclass calling `config_get` or `config_set` will automatically prepend the output of the class's `to_s` method. The default output of this method is not especially helpful as it just identifies the class name:

```
Cisco::CliError: [#<Cisco::Bgp:0x007f1b3b7af5a0>] The command 'foobar shutdown' was rejected with error:
...
```

But by implementing the `to_s` method:

```ruby
module Cisco
  # RouterBgp - node utility class for BGP general config management
  class RouterBgp < NodeUtil
    attr_reader :asnum, :vrf
...
    def to_s
      "BGP #{asnum} VRF '#{vrf}'"
    end
```

The error output can now clearly identify the instance that failed:

```
Cisco::CliError: [BGP 100 VRF 'red'] The command 'foobar shutdown' was rejected with error:
...
```

## MiniTest Best Practices:

### <a name="mt1">MT1: Ensure that *all new API's* have minitest coverage.

Running minitest will automatically produce code coverage results using the [SimpleCov](http://www.rubydoc.info/gems/simplecov) Gem:

```
test_interface:
39 runs, 316 assertions, 0 failures, 0 errors, 2 skips
Coverage report generated for MiniTest to cisco-network-node-utils/coverage. 602 / 814 LOC (73.96%) covered.
```

If you are adding new APIs, after running the tests, you should inspect the coverage results (open `coverage/index.html` with a web browser) to ensure that your new APIs are being exercised appropriately by your new tests.

### <a name="mt2">MT2: Use appropriate `assert_foo` and `refute_foo` statements rather than `assert_equal`.


Minitest has a bunch of different test methods that are more specific than assert_equal. See [test methods](http://docs.ruby-lang.org/en/2.1.0/MiniTest/Assertions.html) for a complete list, but here are some general guidelines:

| Instead of ...                | Use ...           |
| ------------------------------|:-----------------:|
| assert_equal(true, foo.bar?)  | assert(foo.bar?)  |
| assert_equal(false, foo.bar?) | refute(foo.bar?)  |
| assert_equal(true, foo.nil?)  | assert_nil(foo)   |
| assert_equal(false, foo.nil?) | refute_nil(foo)   |
| assert_equal(true, foo.empty?)| assert_empty(foo) |

The more specific assertions also produce more helpful failure messages if something is wrong.

### <a name="mt3">MT3: Do not hardcode interface names.

Rather then hardcode an interface name that may or may not exist, instead use the `interfaces[]` array.

```ruby
def create_interface(ifname=interfaces[0])
  @default_show_command = show_cmd(ifname)
  Interface.new(ifname)
end
```

If additional interfaces are needed array index `1` and `2` may be used.

### <a name="mt4">MT4: Make use of the `config` helper method for device configuration instead of `@device.cmd`.

For conveninence the `config` helper method has been provided for device configuration within the minitests.

```ruby
config('no feature ospf')
```

```ruby
config('feature ospf'; 'router ospf green')
```

### <a name="mt5">MT5: Make use of the `assert_show_match` and `refute_show_match` helper methods to validate expected outcomes in the CLI instead of `@device.cmd("show...")`.

We have a very common pattern in minitest where we execute some show command over the telnet connection, match it against some regexp pattern, and succeed or fail based on the result. Helper methods `assert_show_match` and `refute_show_match` support this pattern.

```ruby
assert_show_match(command: 'show run all | no-more',
                  pattern: /interface port-channel 1/,
                  msg:     'port-channel is not present but it should be')
```

If your `command` and/or `pattern` are the same throughout a test case or throughout a test suite, you can set the test case instance variables `@default_show_command` and/or `@default_output_pattern` which serve as defaults for these parameters:

```ruby
@default_show_command = 'show run interface all | include "interface" | no-more'
assert_output_match(pattern: /interface port-channel 10/)
refute_output_match(pattern: /interface port-channel 11/)
refute_output_match(pattern: /interface port-channel 12/)
assert_output_match(pattern: /interface port-channel 13/)
```

### <a name="mt6">MT6: Unsupported properties must include negative test cases.

Some properties are only applicable to a particular platform and are unsupported on other platforms. To ensure that this lack of support is properly validated, at least one of the test cases for this property should include tests of the getter and default methods and a negative test for the setter method. If you followed [Y11](#yaml11), this means checking that the getter and default methods return `nil` and the setter method raises a `Cisco::UnsupportedError`:

```ruby
def test_foo_bar
  if platform == :platform_not_supporting_bar
    assert_nil(foo.bar)
    assert_nil(foo.default_bar)
    assert_raises(Cisco::UnsupportedError) { foo.bar = baz }
  else
    # tests for foo.bar on a platform that supports this
    ...
```
