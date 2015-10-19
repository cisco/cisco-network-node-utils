# Develoment Best Practices for cisco_node_utils APIs.

* [Overview](#overview)
* [YAML Development Best Practices](#ydbp)
* [Common Object Development Best Practices](#odbp)
* [MiniTest Development Best Practices](#mdbp)

## <a name="overview">Overview</a>

This document is intended to assist in developing cisco_node_utils API's that are consistent with current best practices.


## <a name="ydbp">YAML Development Best Practices</a>

* [Y1](#yaml1): All yaml feature entries should be kept in alphabetical order.
* [Y2](#yaml2): Use anchors where needed for `config_get` and `config_get_token` entries.
* Y3: Avoid nested optional matches.
* [Y4](#yaml4): Use the `_template` feature when getting/setting the same value at multiple levels.
* [Y5](#yaml5): When possible include a `default_value` that represents the system default value and document properties that don't have a system default. **Use strings rather then symbols when applicable**.
* [Y6](#yaml6): When possible, use the same `config_get` show command for all properties and document any anomalies.
* [Y7](#yaml7): Use Key-value wildcards instead of Printf-style wildcards.
* Y8: Use of the `show running all` command is encouraged over `show <feature>` commands since not all `show <feature>` commands behave in the same manner across different cisco platforms.



## <a name="odbp">Common Object Development Best Practices</a>

* [CO1](#co1): If your feature can be configured under the `global` and `non-global vrfs` make sure to account for this in your object design.
* [CO2](#co2): Make use of the equality operator allowing proper `instance1 == instance2` checks in the minitests.
* [CO3](#co3): Let `''` represent 'not configured at all' rather then `nil` unless the property has a default value.
* [CO4](#co4): Make sure all new properites have a `getter`, `setter` and `default_getter` method.
* [CO5](#co5): Use singleton-like design for resources that cannot have mulitple instances.

## <a name="mdbp">MiniTest Development Best Practices</a>

* MT1: Ensure that **all new API's** have minitest coverage.
* [MT2](#mt2): Use appropriate `assert_foo` and `refute_foo` statements rather than `assert_equal`.
* [MT3](#mt3): Do not hardcode interface names.
* [MT4](#mt4): Make use of the `config` helper method for device configuration instead of `@device.cmd`.
* [MT5](#mt5): Make use of the `assert_show_match` and `refute_show_match` helper methods to validate expected outcomes in the CLI instead of `@device.cmd("show...")`.



## YAML Examples:

### <a name="yaml1">Example - Y1 Alpha Order:

```
aaa_authentication_login:  <------ Feature Name
  ascii_authentication:    
...
dnsclient:  <------ Feature Name
  domain:  
```

### <a name="yaml2">Example - Y2 Anchor Use:

```
syslog_settings:
  timestamp:
    config_get: "show running-config all | include '^logging timestamp'"
    config_get_token: '/^logging timestamp (.*)$/'
    config_set: '<state> logging timestamp <units>'
    default_value: 'seconds'
```

### <a name="yaml3">Example - Y3

### <a name="yaml4">Example - Y4 Template Feature:

Using the template below, `auto_cost` and `default_metric` can be set under `router ospf foo` and `router ospf foo; vrf blue`.

```
ospf:
  _template:
    config_get: "show running ospf all"
    config_get_token: '/^router ospf <name>$/'
    config_get_token_append:
      - '/^vrf <vrf>$/'
    config_set: "router ospf <name>"
    config_set_append:
      - "vrf <vrf>"

  auto_cost:
    config_get_token_append: '/^auto-cost reference-bandwidth (\d+)\s*(\S+)?$/'
    config_set_append: "auto-cost reference-bandwidth <cost> <type>"
    default_value: [40, "Gbps"]

  default_metric:
    config_get_token_append: '/^default-metric (\d+)?$/'
    config_set_append: "<state> default-metric <metric>"
    default_value: 0
```

### <a name="yaml5">Example - Y5 Default Values:

Default value for `message_digest_alg_type` is `md5`

```
message_digest_alg_type:
    config_get: 'show running interface all'
    config_get_token: ['/^interface %s$/i', '/^\s*ip ospf message-digest-key \d+ (\S+)/']
    default_value: 'md5'
```

### <a name="yaml6">Example - Y6 Common Show Command:

All properties below use the `show run tacacs all` command except `directed_request` which is documented.

```
tacacs_server:
  deadtime:
    config_get: "show run tacacs all"
    config_get_token: '/^tacacs-server deadtime\s+(\d+)/'
    config_set: "%s tacacs-server deadtime %d"
    default_value: 0

  directed_request:
    # oddly, directed request must be retrieved from aaa output
    config_get: "show running aaa all"
    config_get_token: '/(?:no)?\s*tacacs-server directed-request/'
    config_set: "%s tacacs-server directed-request"
    default_value: false

  encryption_type:
    config_get: "show run tacacs all"
    config_get_token: '/^tacacs-server key (\d+)\s+(\S+)/'
    default_value: 0

  encryption_password:
    config_get: "show run tacacs all"
    config_get_token: '/^tacacs-server key (\d+)\s+(\S+)/'
    default_value: ""
```

### <a name="yaml7">Example - Y7 Wildcard Use:

**Key-value wildcards**

```
config_set_append: "<state> log-adjacency-changes <type>"
```

**Printf-style wildcards**

```
config_set_append: "%s log-adjacency-changes %s"
```

## Common Object Examples:

### <a name="co1">Example - CO1 VRF Handling:

The following `initialize` and `self.vrfs` methods account for configuration under `default` and `non-default vrfs`.

```
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

### <a name="co2">Example - CO2 Equality Operator:

Having this logic defined in the common object lets the minitest easily check the specific instances.

Without this equality operator `==` only passes if they are the same instance object.  With this equality operator `==` passes if they are different objects referring to the same configuration on the node.

```
  def ==(other)
    (name == other.name) && (vrf == other.vrf)
  end
```

Example Usage:

```
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
### <a name="co3">Example - CO3 Default Handling:

Our convention is to let `''` represent 'not configured at all' rather than `nil`. For example, `interface.rb`:

```
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

```
def access_vlan
  vlan = config_get('interface', 'access_vlan', @name)
  return default_access_vlan if vlan.nil?
  vlan.shift.to_i
end

def access_vlan=(vlan)
  config_set('interface', 'access_vlan', @name, vlan)
```

### <a name="co4">Example - CO4 Property Methods:

In the following example, the `router_id` property has a `getter`, `setter` and `default_getter` method.


```
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

### <a name="co5">Example - CO4 Singleton Resources:

See [TacacsServer](../lib/cisco_node_utils/tacacs_server.rb) and [SnmpServer](../lib/cisco_node_utils/snmpserver.rb) for examples.

## MiniTest Examples:

### <a name="mt2">Example - MT2 Use Proper Asserts:

Minitest has a bunch of different test methods that are more specific than assert_equal. See [test methods](http://docs.ruby-lang.org/en/2.1.0/MiniTest/Assertions.html) for a complete list, but here are some general guidelines:

| Instead of ...                | Use ...           |
| ------------------------------|:-----------------:|
| assert_equal(true, foo.bar?)  | assert(foo.bar?)  |
| assert_equal(false, foo.bar?) | refute(foo.bar?)  |
| assert_equal(true, foo.nil?)  | assert_nil(foo)   |
| assert_equal(false, foo.nil?) | refute_nil(foo)   |
| assert_equal(true, foo.empty?)| assert_empty(foo) |

The more specific assertions also produce more helpful failure messages if something is wrong.

### <a name="mt3">Example - MT3 Don't Hardcode Interface:

Use the `interfaces[]` array instead.

```
def create_interface(ifname=interfaces[0])
  @default_show_command = show_cmd(ifname)
  Interface.new(ifname)
end
```

### <a name="mt4">Example - MT4 `config` Helper Method:

```
config('no feature ospf')
```

```
config('feature ospf'; 'router ospf green')
```

### <a name="mt5">Example - MT5 `assert_show_match` and `refute_show_match` Helper Methods:

#### `assert_show_match`

```
  def test_routerospf_create_valid_multiple_delete_one
    name = 'ospfTest_1'
    ospf_1 = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "Error: #{name}, not configured")

    name = 'ospfTest_2'
    ospf_2 = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "Error: #{name}, not configured")

    ospf_1.destroy

    # Remove one router then check that we only have one router left
    routers = RouterOspf.routers
    assert_equal(false, routers.empty?,
                 'Error: RouterOspf collection is empty')
    assert_equal(1, routers.size,
                 'Error: RouterOspf collection is not one')
    assert_equal(true, routers.key?(name),
                 "Error: #{name}, not found in the collection")
    # validate the collection
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "Error: #{name}, instance not found")
    ospf_2.destroy
  end
```

#### `refute_show_match`

```
  def test_interfaceospf_cost
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    cost = 1000
    # set with value
    interface.cost = cost
    assert_show_match(pattern: /\s+ip ospf cost #{cost}/,
                      msg:     'Error: cost missing in CLI')
    assert_equal(cost, interface.cost,
                 'Error: cost get value mismatch')
    # set default
    interface.cost = interface.default_cost
    refute_show_match(pattern: /\s+ip ospf cost(.*)/,
                      msg:     'Error: default cost set failed')
  end
```
