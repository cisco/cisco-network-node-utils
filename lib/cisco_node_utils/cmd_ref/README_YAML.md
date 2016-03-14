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
      * [Optional tokens in key-value lists](#optional-tokens-in-key-value-lists)
* [Advanced attribute definition](#advanced-attribute-definition)
  * [`_template`](#_template)
  * [Data format variants](#data-format-variants)
  * [Platform variants](#platform-variants)
  * [Product variants](#product-variants)
  * [`_exclude`](#_exclude)
  * [YAML anchors and aliases](#YAML-anchors-and-aliases)
  * [Combinations of these](#combinations-of-these)
* [Attribute properties](#attribute-properties)
  * [`get_data_format`](#get_data_format)
  * [`get_command`](#get_command)
  * [`get_context`](#get_context)
  * [`get_value`](#get_value)
  * [`set_context`](#set_context)
  * [`set_value`](#set_value)
  * [`default_value`](#default_value)
  * [`default_only`](#default_only)
  * [`kind`](#kind)
  * [`multiple`](#multiple)
  * [`auto_default`](#auto_default)
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
  get_command: "show vtp status"
  get_value: "domain_name"
  set_value: "vtp domain <domain>"

filename:
  get_command: "show running vtp"
  get_value: '/vtp file (\S+)/'
  set_value: "<state> vtp file <filename>"
  default_value: ""
```

In the above example, two attributes are defined: ('vtp', 'domain') and ('vtp',
'filename').

Note that all attribute properties are optional and may be omitted if not
needed. In the above, example 'domain' does not have a value defined for
`default_value` but 'filename' does have a default.

### Wildcard substitution

The `(get|set)_(context|value)` properties all support two forms of wildcarding - printf-style and key-value. Each has advantages and disadvantages but key-value is generally preferred for a number of reasons as seen below:

<table>
<tr><th></th><th>Advantages</th><th>Disadvantages</th></tr>
<tr>
  <th>Printf-style</th>
  <td><ul><li>Quick to implement, concise</li></ul></td>
  <td><ul><li>Can't handle differences in wildcard order between nodes</li>
    <li>Can't handle differences in wildcard count between nodes</li>
    <li>Can't support optional tokens (e.g., VRF context)</li>
    <li>Less readable in Ruby code (not obvious which parameters mean what)</li>
  </ul></td>
</tr><tr>
  <th>Key-Value</th>
  <td><ul><li>Can handle differences in wildcard order/count between nodes</li>
    <li>Can handle differences in which wildcards are used on various nodes</li>
    <li>Can flag tokens as optional (see below)</li>
    <li>More readable Ruby code due to parameter labels</li>
  </ul></td>
  <td><ul><li>Slightly more complex to implement than printf-style</li>
    <li>Slightly more verbose YAML and Ruby code</li>
  </ul></td>
</tr></table>

#### Printf-style wildcards

```yaml
# tacacs_server_host.yaml
encryption:
  set_value: '%s tacacs-server host %s key %s %s'
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
  set_context: 'router ospf <name>'
  set_value: 'auto-cost reference-bandwidth <cost> <type>'
```

This requires parameter values to be passed as a hash:

```ruby
irb(main):015:0> ref = cr.lookup('ospf', 'auto_cost')
irb(main):016:0> ref.config_set(name: 'red', cost: '40', type: 'Gbps')
=> ["router ospf red", "auto-cost reference-bandwidth 40 Gbps"]
```

Key-value wildcards are moderately more complex to implement than Printf-style wildcards but they are more readable in the Ruby code and are flexible enough to handle significant platform differences in CLI. Key-value wildcards are therefore the recommended approach for new development.

##### Optional tokens in key-value lists

When defining `(get|set)_context` entries with key-value wildcards, it is possible to mark some or all of the tokens in the context as optional by prepending `(?)` to them. A common example of this is to support properties that can be defined either globally or under a VRF routing context:

```yaml
# bgp.yaml
confederation_peers:
  ios_xr:
    get_context:
      - 'router bgp <asnum>'
      - '(?)/^vrf <vrf>$/i'
      - 'bgp confederation peers'
```

An optional token will be omitted if any of the wildcards in this token do not have an assigned value. By contrast, mandatory tokens (i.e., any token not explicitly flagged as optional) will raise an ArgumentError if wildcard values are missing:

```ruby
irb(main):003:0> ref = node.cmd_ref.lookup('bgp', 'confederation_peers')
irb(main):006:0> ref.getter(asnum: 1)[:context]
=> ["router bgp 1", "bgp confederation peers"]
irb(main):007:0> ref.getter(asnum: 1, vrf: 'red')[:context]
=> ["router bgp 1", "/^vrf red$/i", "bgp confederation peers"]
irb(main):008:0> ref.getter(vrf: 'red')[:context]
ArgumentError: No value specified for 'asnum' in 'router bgp <asnum>'
```

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
  get_command: 'show running-config interface all'
  get_context: 'interface <name>'
  set_context: 'interface <name>'

access_vlan:
  get_value: 'switchport access vlan (.*)'
  set_value: 'switchport access vlan <number>'

description:
  get_value: '/^description (.*)$/'
  set_value: 'description <desc>'

...
```

instead of the more repetitive (but equally valid):

```yaml
# interface.yaml
access_vlan:
  get_command: 'show running interface all'
  get_context: 'interface <name>'
  get_value: 'switchport access vlan (.*)'
  set_context: 'interface <name>'
  set_value: 'switchport access vlan <number>'

description:
  get_command: 'show running-config interface all'
  get_context: 'interface <name>'
  get_value: '/^description (.*)$/'
  set_context: 'interface <name>'
  set_value: 'description <desc>'

...
```

### Data format variants

Clients for different Cisco platforms may use different data formats. NXAPI (used for Cisco Nexus platforms) supports a CLI-based data format (essentially a wrapper for the Nexus CLI) as well as a NXAPI-specific structured format for some 'show' commands. Currently the gRPC client provided here (used for Cisco IOS XR platforms) supports a CLI-based format. Other platforms may have other formats such as YANG. As different formats have different requirements, the YAML must be able to accommodate this.

CLI is the lowest common denominator, so YAML entries not otherwise flagged as applicable to a specific API type will be assumed to reference CLI. Other API types can be indicated by using the API type as a key (`cli`, `nxapi_structured`, `yang`, etc.). For example, Nexus platforms support a structured form of 'show version', while other clients might use the same command but will need to parse CLI output with a regular expression:

```yaml
# show_version.yaml
description:
  get_command: 'show version'
  nexus:
    data_format: nxapi_structured
    get_value: 'chassis_id'
  else:
    data_format: cli
    get_value: '/Hardware\n  cisco (([^(\n]+|\(\d+ Slot\))+\w+)/'
```

### Platform variants

Even for clients using the same data format (e.g., CLI), there may be differences between classes of Cisco platform.  Any of the attribute properties can be subdivided by platform type by using the platform type as a key. For example, interface VRF membership defaults to `""` (no VRF) on both Nexus and IOS XR platforms, but the CLI is `vrf member <vrf>` for Nexus and `vrf <vrf>` for IOS XR. Thus, the YAML could be written as:

```yaml
# interface.yaml
vrf:
  default_value: ""
  nexus:
    get_value: 'vrf member (.*)'
    set_value: "<state> vrf member <vrf>"
  ios_xr:
    get_value: 'vrf (.*)'
    set_value: "<state> vrf <vrf>"
```

### Product variants

Various product categories can also be used as keys to subdivide attributes as needed. Supported categories currently include the various Nexus switch product lines (`N3k`, `N5k`, `N6k`. `N7k`, `N9k`). When using one or more product keys in this fashion, you can also use the special key `else` to handle all other products not specifically called out:

```yaml
# show_version.yaml
system_image:
  N9k:
    get_value: "kick_file_name"
  else:
    get_value: "isan_file_name"
```

### `_exclude`

Related to product variants, an `_exclude` entry can be used to mark an entire feature or a given feature attribute as not applicable to a particular set of products. For example, if feature 'fabricpath' doesn't apply to the N3K or N9K platforms, it can be excluded altogether from those platforms by a single `_exclude` entry at the top of the file:

```yaml
# fabricpath.yaml
---
_exclude: [N3k, N9k]

_template:
...
```

Individual feature attributes can also be excluded in this way:

```yaml
attribute:
  _exclude:
    - N7k
  default_value: true
  get_command: 'show attribute'
  set_value: 'attribute'
```

When a feature or attribute is excluded in this way, attempting to call `config_get` or `config_set` on an excluded node will result in a `Cisco::UnsupportedError` being raised. Calling `config_get_default` on such a node will always return `nil`.

### YAML anchors and aliases

To reduce repetition, YAML provides the functionality of [node anchors](http://www.yaml.org/spec/1.2/spec.html#id2785586) and [node aliases](http://www.yaml.org/spec/1.2/spec.html#id2786196). A node anchor can be defined with the syntax `&anchor_name` and other nodes can alias against this anchor with the syntax `*anchor_name`. For example, to provide the same data for N3k and N9k platforms:

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

### Combinations of these

In many cases, supporting multiple platforms and multiple products will require
using several or all of the above options.

Using `_template` in combination with platform and data format variants:

```yaml
# inventory.yaml
_template:
  ios_xr:
    get_command: 'show inventory | begin "Rack 0"'
    get_data_format: cli
  nexus:
    get_command: 'show inventory'
    get_data_format: nxapi_structured

productid:
  ios_xr:
    get_value: '/PID: ([^ ,]+)/'
  nexus:
    get_context: ["TABLE_inv", "ROW_inv", 0]
    get_value: "productid"
```

Using platform variants and product variants together:

```yaml
# interface.yaml
negotiate_auto_portchannel:
  kind: boolean
  _exclude: [ios_xr]
  nexus:
    N7k:
      default_only: false
    else:
      get_value: '(no )?negotiate auto'
      set_value: "<state> negotiate auto"
      default_value: true
```

## Attribute properties

### `get_data_format`

The `get_data_format` key is optionally used to specify which data format a given client should use for a get operation. Supported values are `cli` and `nxapi_structured`. If not specified, this key defaults to `cli`.

```yaml
# inventory.yaml
productid:
  get_command: 'show inventory'
  nexus:
    get_data_format: nxapi_structured
    get_context: ['TABLE_inv', 'ROW_inv', 0]
```

### `get_command`

`get_command` must be a single string representing the CLI command (usually a
`show` command) to be used to display the information needed to get the
current value of this attribute.

```yaml
# interface_ospf.yaml
area:
  get_command: 'show running interface all'
```

### `get_context`

`get_context` is an optional sequence of tokens used to filter the output from the `get_command` down to the desired context where the `get_value` can be found. For CLI properties, these tokens are implicitly Regexps used to filter down through the hierarchical CLI output, while for `nxapi_structured` properties, the tokens are used as string keys.


```yaml
# inventory.yaml
productid:
  get_command: 'show inventory'
  nexus:
    get_data_format: nxapi_structured
    get_context: ['TABLE_inv', 'ROW_inv', 0]
    get_value: 'productid'
    # config_get('inventory', 'productid') returns
    # structured_output['TABLE_inv']['ROW_inv'][0]['productid']
```

```yaml
# interface.yaml
description:
  get_command: 'show running interface all'
  ios_xr:
    get_context: 'interface <name>'
    get_value: '/^description (.*)/'
    # config_get('interface', 'description', name: 'Ethernet1/1') gets the
    # plaintext output, finds the subsection under /^interface Ethernet1/1$/i,
    # then finds the line matching /^description (.*)$/ in that subsection
```

If the context is defined using the recommended key-value wildcarding style, it is possible to define individual tokens as [optional](#optional-tokens-in-key-value-lists).

### `get_value`

`get_value` is the specific token used to locate the desired value. As with `get_context`, this is implicitly a Regexp for a CLI command, and implicitly a Hash key for a `nxapi_structured` command.

When using a `_template` section, a common pattern is to place the `get_context` in the template to be shared among all attributes, then have specific `get_value` defined for each individual attribute:

```yaml
# interface.yaml
_template:
  get_command: 'show running-config interface all'
  get_context: 'interface <name>'

description:
  get_value: '/^description (.*)$/'

duplex:
  get_value: 'duplex (.*)'
```

### `set_context`

The optional `set_context` parameter is a sequence of strings representing the
configuration CLI command(s) used to enter the necessary configuration submode before configuring the attribute's `set_value`.

```yaml
# interface.yaml
description:
  set_context: ['interface <name>']
  set_value: 'description <desc>'
```

If the context is defined using the recommended key-value wildcarding style, it is possible to define individual tokens as [optional](#optional-tokens-in-key-value-lists).

### `set_value`

`set_value` is the specific command used to set the desired attribute value. As with `get_value`, a common pattern is to specify a `set_context` in the `_template` section and specify `set_value` on a per-attribute basis:

```yaml
# interface.yaml
_template:
  set_context: ['interface <name>']

access_vlan:
  set_value: 'switchport access vlan <number>'

description:
  set_value: '<state> description <desc>'
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

`config_get()` will return the defined `default_value` if the defined `get_value` does not match anything on the node. Normally this is desirable behavior, but you can use [`auto_default`](#auto_default) to change this behavior if needed.

### `default_only`

Some attributes may be hard-coded in such a way that they have a meaningful default value but no relevant `get_value` or `set_value` behavior. For such attributes, the key `default_only` should be used as an alternative to `default_value`. The benefit of using this key is that it causes the `config_get()` API to always return the default value and `config_set()` to raise a `Cisco::UnsupportedError`.

```yaml
negotiate_auto_ethernet:
  kind: boolean
  nexus:
    /(N7|C3064)/:
      # this feature is always off on these platforms and cannot be changed
      default_only: false
    else:
      get_value: '(no )?negotiate auto'
      set_value: "%s negotiate auto"
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
  get_value: 'switchport access vlan (.*)'
  set_value: "switchport access vlan <vlan>"
  kind: int
  default_value: 1

description:
  kind: string
  get_value: 'description (.*)'
  set_value: "<state> description <desc>"
  default_value: ""

feature_lacp:
  kind: boolean
  get_command: "show running | i ^feature"
  get_value: 'feature lacp'
  set_value: "<state> feature lacp"
```

### `multiple`

By default, `get_value` should uniquely identify a single configuration entry, and `config_get()` will raise an error if more than one match is found. For a small number of attributes, it may be desirable to permit multiple matches (in particular, '`all_*`' attributes that are used up to look up all interfaces, all VRFs, etc.). For such attributes, you must specify the key `multiple:`. When this key is present, `config_get()` will permit multiple matches and will return an array of matches (even if there is only a single match).

```yaml
# interface.yaml
---
all_interfaces:
  multiple:
  get_value: 'interface (.*)'
```

### `auto_default`

Normally, if `get_value` produces no match, `config_get()` will return the defined `default_value` for this attribute. For some attributes, this may not be desirable. Setting `auto_default: false` will force `config_get()` to return `nil` in the non-matching case instead.

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
  get_value: 'dampen-igp-metric (\d+)'
  set_value: '<state> dampen-igp-metric <num>'
```

## Style Guide

Please see [YAML Best Practices](../../../docs/README-develop-best-practices.md#ydbp).
