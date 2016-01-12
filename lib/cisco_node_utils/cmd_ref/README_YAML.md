# Command Reference YAML

The [YAML](http://yaml.org) files in this directory are used with the
`Cisco::CommandReference` module as a way to abstract away differences
between client APIs as well as differences between platforms sharing
the same client API.

This document describes the structure and semantics of these files.

* [Introduction](#introduction)
* [Basic attribute definition](#basic-attribute-definition)
  * [Wildcard substitution](#wildcard-substitution)
    * [Printf-style wildcards](#printf-style-wildcards)
    * [Key-value wildcards](#key-value-wildcards)
* [Advanced attribute definition](#advanced-attribute-definition)
  * [`_template`](#_template)
  * [Platform and API variants](#platform-and-api-variants)
  * [Product variants](#product-variants)
  * [`_exclude`](#_exclude)
  * [Combinations of these](#combinations-of-these)
* [Attribute properties](#attribute-properties)
  * [`config_get`](#config_get)
  * [`config_get_token`](#config_get_token)
  * [`config_get_token_append`](#config_get_token_append)
  * [`config_set`](#config_set)
  * [`config_set_append`](#config_set_append)
  * [`default_value`](#default_value)
  * [`default_only`](#default_only)
  * [`kind`](#kind)
  * [`multiple`](#multiple)
  * [`auto_default`](#auto_default)
  * [`test_config_get` and `test_config_get_regex`](#test_config_get-and-test_config_get_regex)
  * [`test_config_result`](#test_config_result)
* [Style Guide](#style-guide)

## Introduction

Each file describes a single 'feature' (a closely related set of
configurable attributes). The YAML within the file defines the set of
'attributes' belonging to this feature. When a `CommandReference` object
is instantiated, the user can look up any given attribute using the
`lookup('feature_name', 'attribute_name')` API. Usually, instead of calling
this API directly, node utility classes will call the various `Node` APIs,
for example:

```ruby
config_set('feature_name', 'attribute_name', *args)
value = config_get('feature_name', 'attribute_name')
default = config_get_default('feature_name', 'attribute_name')
```

## Basic attribute definition

The simplest definition of an attribute directly sets one or more properties
of this attribute. These properties' values can generally be set to any
basic Ruby type such as string, boolean, integer, array, or regexp.
An example:

```yaml
# vtp.yaml
domain:
  config_get: "show vtp status"
  config_get_token: "domain_name"
  config_set: "vtp domain <domain>"

filename:
  config_get: "show running vtp"
  config_get_token: '/vtp file (\S+)/'
  config_set: "<state> vtp file <filename>"
  default_value: ""
```

In the above example, two attributes are defined: ('vtp', 'domain') and ('vtp',
'filename').

Note that all attribute properties are optional and may be omitted if not
needed. In the above, example 'domain' does not have a value defined for
`default_value` but 'filename' does have a default.

### Wildcard substitution

The `config_get_token` and `config_set` properties (and their associated
`_append` variants) all support two forms of wildcarding - printf-style and
key-value. Key-value is generally preferred, as described below.

#### Printf-style wildcards

```yaml
# tacacs_server_host.yaml
encryption:
  config_set: '%s tacacs-server host %s key %s %s'
```

This permits parameter values to be passed as a simple sequence to generate the resulting string or regexp:

```ruby
irb(main):009:0> ref = cr.lookup('tacacs_server_host', 'encryption')
irb(main):010:0> ref.config_set('no', 'myhost', 'md5', 'mypassword')
=> ["no tacacs-server host myhost key md5 mypassword"]
```

Printf-style wildcards are quick to implement and concise, but less flexible - in particular they cannot handle a case where different platforms (or different
client APIs!) take parameters in a different order - and less readable in
the Ruby code.

#### Key-value wildcards

```yaml
# ospf.yaml
auto_cost:
  config_set: ['router ospf <name>', 'auto-cost reference-bandwidth <cost> <type>']
```

This requires parameter values to be passed as a hash:

```ruby
irb(main):015:0> ref = cr.lookup('ospf', 'auto_cost')
irb(main):016:0> ref.config_set(name: 'red', cost: '40', type: 'Gbps')
=> ["router ospf red", "auto-cost reference-bandwidth 40 Gbps"]
```

Array elements that contain a parameter that is *not* included in the argument hash are not included in the result:

```ruby
irb(main):017:0> ref.config_set(name: 'red', cost: '40')
=> ["router ospf red"]
```

If this process results in an empty array, then an `ArgumentError` is raised to indicate that not enough parameters were supplied.

Key-value wildcards are moderately more complex to implement than Printf-style wildcards but they are more readable in the Ruby code and are flexible enough to handle significant platform differences in CLI. Key-value wildcards are therefore the recommended approach for new development.

## Advanced attribute definition

### `_template`

The optional `_template` section can be used to define base parameters for all
attributes of a given feature. For example, all interface attributes might be
checked with the `show running-config interface all` command, and all
attributes might be set by first entering the interface configuration submode
with the `interface <name>` configuration command. Thus, you might have:

```yaml
# interface.yaml
_template:
  config_get: 'show running-config interface all'
  config_get_token: '/^interface <name>$/'
  config_set: 'interface <name>'

access_vlan:
  config_get_token_append: '/^switchport access vlan (.*)$/'
  config_set_append: 'switchport access vlan <number>'

description:
  config_get_token_append: '/^description (.*)$/'
  config_set_append: 'description <desc>'

...
```

instead of the more repetitive (but equally valid):

```yaml
# interface.yaml
access_vlan:
  config_get: 'show running interface all'
  config_get_token: ['/^interface <name>$/i', '/^switchport access vlan (.*)$/']
  config_set: ['interface <name>', 'switchport access vlan <number>']

description:
  config_get: 'show running-config interface all'
  config_get_token: ['/^interface <name>$/i', '/^description (.*)$/']
  config_set: ['interface <name>', 'description <desc>']

...
```

### Platform and API variants

Clients for different Cisco platforms may use different APIs. Currently the only supported API is NXAPI (CLI-based API used for Cisco Nexus platforms). Often the CLI or other input/output formats (YANG, etc.) needed will vary between APIs, so the YAML must be able to accomodate this.

Any of the attribute properties can be subdivided by platform and API type by using the
combination of API type and platform type as a key. For example, interface VRF membership defaults to "" (no VRF) on both Nexus and IOS XR platforms, but the CLI is 'vrf member <vrf>' for Nexus and 'vrf <vrf>' for IOS XR. Thus, the YAML could be written as:

```yaml
# interface.yaml
vrf:
  default_value: ""
  cli_nexus:
    config_get_token_append: '/^vrf member (.*)/'
    config_set_append: "<state> vrf member <vrf>"
```

and later, once we have a CLI-based API for IOS XR, this could be extended:

```yaml
# interface.yaml
vrf:
  default_value: ""
  cli_nexus:
    config_get_token_append: '/^vrf member (.*)/'
    config_set_append: "<state> vrf member <vrf>"
  cli_ios_xr:
    config_get_token_append: '/^vrf (.*)/'
    config_set_append: "<state> vrf <vrf>"
```

### Product variants

Any of the attribute properties can be subdivided by platform product ID string
using a regexp against the product ID as a key. When one or more regexp keys
are defined thus, you can also use the special key `else` to provide values
for all products that do not match any of the given regexps:

```yaml
# show_version.yaml
system_image:
  /N9/:
    config_get_token: "kick_file_name"
    test_config_get_regex: '/.*NXOS image file is: (.*)$.*/'
  else:
    config_get_token: "isan_file_name"
    test_config_get_regex: '/.*system image file is:    (.*)$.*/'
```

### `_exclude`

Related to product variants, an `_exclude` entry can be used to mark an entire feature or a given feature attribute as not applicable to a particular set of products. For example, if feature 'fabricpath' doesn't apply to the N3K or N9K platforms, it can be excluded altogether from those platforms by a single `_exclude` entry at the top of the file:

```yaml
# fabricpath.yaml
---
_exclude: [/N3/, /N9/]

_template:
...
```

Individual feature attributes can also be excluded in this way:

```yaml
attribute:
  _exclude:
    - /N7/
  default_value: true
  config_get: 'show attribute'
  config_set: 'attribute'
```

When a feature or attribute is excluded in this way, attempting to call `config_get` or `config_set` on an excluded node will result in a `Cisco::UnsupportedError` being raised. Calling `config_get_default` on such a node will always return `nil`.

### Combinations of these

In many cases, supporting multiple platforms and multiple products will require
using several or all of the above options.

Using `_template` in combination with API variants:

```yaml
# inventory.yaml
_template:
  cli_ios_xr:
    config_get: 'show inventory | begin "Rack 0"'
    test_config_get: 'show inventory'
  cli_nexus:
    config_get: 'show inventory'
    test_config_get: 'show inventory | no-more'

productid:
  cli_ios_xr:
    config_get_token: '/PID: ([^ ,]+)/'
  cli_nexus:
    config_get_token: ["TABLE_inv", "ROW_inv", 0, "productid"]
```

Using platform variants and product variants together:

```yaml
# inventory.yaml
description:
  config_get_token: "chassis_id"
  cli_nexus:
    /N7/:
      test_config_get_regex: '/.*Hardware\n  cisco (\w+ \w+ \(\w+ \w+\) \w+).*/'
    else:
      test_config_get_regex: '/Hardware\n  cisco (([^(\n]+|\(\d+ Slot\))+\w+)/'
  cli_ios_xr:
    config_get: 'show inventory | inc "Rack 0"'
    config_get_token: '/DESCR: "(.*)"/'
    test_config_get: 'show inventory | inc "Rack 0"'
    test_config_get_regex: '/DESCR: "(.*)"/'
```

## Attribute properties

### `config_get`

`config_get` must be a single string representing the CLI command (usually a
`show` command) to be used to display the information needed to get the
current value of this attribute.

```yaml
# interface_ospf.yaml
area:
  config_get: 'show running interface all'
```

### `config_get_token`

`config_get_token` can be a single string, a single regex, an array of strings,
or an array of regexs.

If this value is a string or array of strings, then the `config_get` command
will be executed to produce _structured_ output and the string(s) will be
used as lookup keys.

**WARNING: structured output, although elegant, may not be supported for all commands or all platforms. Use with caution.**

```yaml
# show_version.yaml
cpu:
  config_get: 'show version'
  config_get_token: 'cpu_name'
  # config_get('show_version', 'cpu') returns structured_output['cpu_name']
```

```yaml
# inventory.yaml
productid:
  config_get: 'show inventory'
  config_get_token: ['TABLE_inv', 'ROW_inv', 0, 'productid']
  # config_get('inventory', 'productid') returns
  # structured_output['TABLE_inv']['ROW_inv'][0]['productid']
```

If this value is a regexp or array of regexps, then the `config_get` command
will be executed to produce _plaintext_ output.

For a single regexp, it will be used to match against the plaintext.

```yaml
# memory.yaml
total:
  config_get: 'show system resources'
  config_get_token: '/Memory.* (\S+) total/'
  # config_get('memory', 'total') returns
  # plaintext_output.scan(/Memory.* (\S+) total/)
```

For an array of regex, then the plaintext is assumed to be hierarchical in
nature (like `show running-config`) and the regexs are used to filter down
through the hierarchy.

```yaml
# interface.yaml
description:
  config_get: 'show running interface all'
  config_get_token: ['/^interface <name>$/i', '/^description (.*)/']
  # config_get('interface', 'description', name: 'Ethernet1/1') gets the
  # plaintext output, finds the subsection under /^interface Ethernet1/1$/i,
  # then finds the line matching /^description (.*)$/ in that subsection
```

### `config_get_token_append`

When using a `_template` section, an attribute can use
`config_get_token_append` to extend the `config_get_token` value provided by
the template instead of replacing it:

```yaml
# interface.yaml
_template:
  config_get: 'show running-config interface all'
  config_get_token: '/^interface <name>$/i'

description:
  config_get_token_append: '/^description (.*)$/'
  # config_get_token value for 'description' is now:
  # ['/^interface <name>$/i', '/^description (.*)$/']
```

This can also be used to specify conditional tokens which may or may not be
used depending on the set of parameters passed into `config_get()`:

```yaml
# ospf.yaml
_template:
  config_get: 'show running ospf all'
  config_get_token: '/^router ospf <name>$/'
  config_get_token_append:
    - '/^vrf <vrf>$/'

router_id:
  config_get_token_append: '/^router-id (\S+)$/'
```

In this example, the `vrf` parameter is optional and a different
`config_get_token` value will be generated depending on its presence or absence:

```ruby
irb(main):008:0> ref = cr.lookup('ospf', 'router_id')
irb(main):012:0> ref.config_get_token(name: 'red')
=> [/^router ospf red$/, /^router-id (\S+)?$/]
irb(main):013:0> ref.config_get_token(name: 'red', vrf: 'blue')
=> [/^router ospf red$/, /^vrf blue$/, /^router-id (\S+)?$/]
```

### `config_set`

The `config_set` parameter is a string or array of strings representing the
configuration CLI command(s) used to set the value of the attribute.

```yaml
# interface.yaml
create:
  config_set: 'interface <name>'

description:
  config_set: ['interface <name>', 'description <desc>']
```

### `config_set_append`

When using a `_template` section, an attribute can use `config_set_append` to
extend the `config_set` value provided by the template instead of replacing it:

```yaml
# interface.yaml
_template:
  config_set: 'interface <name>'

access_vlan:
  config_set_append: 'switchport access vlan <number>'
  # config_set value for 'access_vlan' is now:
  # ['interface <name>', 'switchport access vlan <number>']
```

Much like `config_get_token_append`, this can also be used to specify optional
commands that can be included or omitted as needed:

```yaml
# ospf.yaml
_template:
  config_set: 'router ospf <name>'
  config_set_append:
    - 'vrf <vrf>'

router_id:
  config_set_append: 'router-id <router_id>'
```

```ruby
irb(main):008:0> ref = cr.lookup('ospf', 'router_id')
irb(main):017:0> ref.config_set(name: 'red', state: nil, router_id: '1.1.1.1')
=> ["router ospf red", " router-id 1.1.1.1"]
irb(main):019:0> ref.config_set(name: 'red', vrf: 'blue',
                                state: 'no', router_id: '1.1.1.1')
=> ["router ospf red", "vrf blue", "no router-id 1.1.1.1"]
```

### `default_value`

If there is a default value for this attribute when not otherwise specified by the user, the `default_value` parameter describes it. This can be a string, boolean, integer, array, or nil.

```yaml
description:
  default_value: ''

hello_interval:
  default_value: 10

auto_cost:
  default_value: [40, 'Gbps']

ipv4_address:
  # YAML represents nil as ~
  default_value: ~
```

By convention, a `default_value` of `''` (empty string) represents a configurable property that defaults to absent, while a default of `nil` (Ruby) or `~` (YAML) represents a property that has no meaningful default at all.

`config_get()` will return the defined `default_value` if the defined `config_get_token` does not match anything on the node. Normally this is desirable behavior, but you can use [`auto_default`](#auto_default) to change this behavior if needed.

### `default_only`

Some attributes may be hard-coded in such a way that they have a meaningful default value but no relevant `config_get_token` or `config_set` behavior. For such attributes, the key `default_only` should be used as an alternative to `default_value`. The benefit of using this key is that it causes the `config_get()` API to always return the default value and `config_set()` to raise a `Cisco::UnsupportedError`.

```yaml
negotiate_auto_ethernet:
  kind: boolean
  cli_nexus:
    /(N7|C3064)/:
      # this feature is always off on these platforms and cannot be changed
      default_only: false
    else:
      config_get_token_append: '/^(no )?negotiate auto$/'
      config_set_append: "%s negotiate auto"
      default_value: true
```

### `kind`

The `kind` attribute is used to specify the type of value that is returned by `config_get()`. If unspecified, no attempt will be made to guess the return type and it will typically be one of string, array, or `nil`. If `kind` is specified, type conversion will automatically be performed as follows:

* `kind: boolean` - value will be coerced to `true`/`false`, and if no `default_value` is set, a `nil` result will be returned as `false`.
* `kind: int` - value will be coerced to an integer, and if no `default_value` is set, a `nil` result will be returned as `0`.
* `kind: string` - value will be coerced to a string, leading/trailing whitespace will be stripped, and if no `default_value` is set, a `nil` result will be returned as `''`.

```yaml
# interface.yaml
---
access_vlan:
  config_get_token_append: '/^switchport access vlan (.*)$/'
  config_set_append: "switchport access vlan %s"
  kind: int
  default_value: 1

description:
  kind: string
  config_get_token_append: '/^description (.*)/'
  config_set_append: "%s description %s"
  default_value: ""

feature_lacp:
  kind: boolean
  config_get: "show running | i ^feature"
  config_get_token: '/^feature lacp$/'
  config_set: "%s feature lacp"
```

### `multiple`

By default, `config_get_token` should uniquely identify a single configuration entry, and `config_get()` will raise an error if more than one match is found. For a small number of attributes, it may be desirable to permit multiple matches (in particular, '`all_*`' attributes that are used up to look up all interfaces, all VRFs, etc.). For such attributes, you must specify the key `multiple:`. When this key is present, `config_get()` will permit multiple matches and will return an array of matches (even if there is only a single match).

```yaml
# interface.yaml
---
all_interfaces:
  multiple:
  config_get_token: '/^interface (.*)/'
```

### `auto_default`

Normally, if `config_get_token` produces no match, `config_get()` will return the defined `default_value` for this attribute. For some attributes, this may not be desirable. Setting `auto_default: false` will force `config_get()` to return `nil` in the non-matching case instead.

```yaml
# bgp_af.yaml
---
dampen_igp_metric:
  # dampen_igp_metric defaults to nil (disabled),
  # but its default numeric value when enabled is 600.
  # If disabled, we want config_get() to return nil, not 600.
  default_value: 600
  auto_default: false
  kind: int
  config_get_token_append: '/^dampen-igp-metric (\d+)$/'
  config_set_append: '<state> dampen-igp-metric <num>'
```

### `test_config_get` and `test_config_get_regex`

Test-only equivalents to `config_get` and `config_get_token` - a show command
to be executed over telnet by the minitest unit test scripts, and a regex
(or array thereof) to match in the resulting plaintext output.
Should only be referenced by test scripts, never by a feature provider itself.

```yaml
# show_version.yaml
boot_image:
  test_config_get: 'show version | no-more'
  test_config_get_regex: '/NXOS image file is: (.*)$/'
```

### `test_config_result`

Test-only container for input-result pairs that might differ by platform.
Should only be referenced by test scripts, never by a feature provider itself.

```yaml
# vtp.yaml
version:
  /N7/:
    test_config_result:
      3: 3
  else:
    test_config_result:
      3: 'Cisco::CliError'
```

## Style Guide

Please see [YAML Best Practices](../../../docs/README-develop-best-practices.md#ydbp).
