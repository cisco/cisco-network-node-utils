# Command Reference YAML

The `command_reference_*.yaml` files in this directory are used with the
`CommandReference` module as a way to abstract away platform CLI differences.

This document describes the structure and semantics of these files.

## Structure

```yaml
FEATURE_1:
  _template:
    # base parameters for all attributes of this feature go here

  ATTRIBUTE_1:
    config_get: 'string'
    config_get_token: 'string'
    config_get_token_append: 'string'
    config_set: 'string'
    config_set_append: 'string'
    default_value: string, boolean, integer, or constant
    test_config_get: 'string'
    test_config_get_regexp: '/regexp/'
    test_config_result:
      input_1: output_1
      input_2: output_2

  ATTRIBUTE_2:
    ...

  ATTRIBUTE_3:
    ...

FEATURE_2:
  ...
```

All parameters are optional and may be omitted if not needed.

### Wildcard substitution

The `config_get_token` and `config_set` (and their associated `_append`
variants) all support two forms of wildcarding - printf-style and key-value.

#### Printf-style wildcards

```yaml
tacacs_server_host:
  encryption:
    config_set: '%s tacacs-server host %s key %s %s'
```

This permits parameter values to be passed as a simple sequence:

```ruby
config_set('tacacs_server_host', 'encryption', 'no', 'user', 'md5', 'password')

# this becomes 'no tacacs-server host user key md5 password'
#               ^^                    ^^^^     ^^^ ^^^^^^^^
```

This approach is quick to implement and concise, but less flexible - in
particular it cannot handle a case where different platforms take parameters
in a different order - and less readable in the ruby code.

#### Key-value wildcards

```yaml
ospf:
  auto_cost:
    config_set: ['router ospf <name>', 'auto-cost reference-bandwidth <cost> <type>']
```

This requires parameter values to be passed as a hash:

```ruby
config_set('ospf', 'auto_cost', {:name => 'red',
                                 :cost => '40',
                                 :type => 'Gbps'})

# this becomes the config sequence:
#   router ospf red
#    auto-cost reference-bandwidth 40 Gbps
```

This approach is moderately more complex to implement but is more readable in
the ruby code and is flexible enough to handle significant platform
differences in CLI. It is therefore the recommended approach for new
development.

### `_template`

The optional `_template` section can be used to define base parameters for all
attributes of a given feature. For example, all interface attributes might be
checked with the `show running-config interface all` command, and all
attributes might be set by first entering the interface configuration submode
with the `interface <name>` configuration command. Thus, you might have:

```yaml
interface:
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
interface:
  access_vlan:
    config_get: 'show running interface all'
    config_get_token: ['/^interface %s$/i', '/^switchport access vlan (.*)$/']
    config_set: ['interface %s', 'switchport access vlan %s']

  description:
    config_get: 'show running-config interface all'
    config_get_token: ['/^interface <name>$/i', '/^description (.*)$/']
    config_set: ['interface <name>', 'description <desc>']

  ...
```

### `config_get`

`config_get` must be a single string representing the CLI command (usually a
`show` command) to be used to display the information needed to get the
current value of this attribute.

```yaml
    config_get: 'show running-config interface <name> all'
```

### `config_get_token`

`config_get_token` can be a single string, a single regex, an array of strings,
or an array of regexs.

If this value is a string or array of strings, then the `config_get` command
will be executed to produce _structured_ output and the string(s) will be
used as lookup keys.

```yaml
show_version
  cpu:
    config_get: 'show version'
    config_get_token: 'cpu_name'
    # config_get('show_version', 'cpu') returns structured_output['cpu_name']
```

```yaml
inventory:
  productid:
    config_get: 'show inventory'
    config_get_token: ['TABLE_inv', 'ROW_inv', 0, 'productid']
    # config_get('inventory', 'productid') returns
    # structured_output['TABLE_inv']['ROW_inv'][0]['productid']
```

If this value is a regex or array or regexs, then the `config_get` command
will be executed to produce _plaintext_ output.

For a single regex, it will be used to match against the plaintext.

```yaml
memory:
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
interface:
  description:
    config_get: 'show running interface all'
    config_get_token: ['/^interface %s$/i', '/^description (.*)/']
    # config_get('interface', 'description', 'Ethernet1/1') gets the plaintext
    # output, finds the subsection under /^interface Ethernet1/1$/i, then finds
    # the line matching /^description (.*)$/ in that subsection
```

### `config_get_token_append`

When using a `_template` section, an attribute can use
`config_get_token_append` to extend the `config_get_token` value provided by
the template instead of replacing it:

```yaml
interface:
  _template:
    config_get: 'show running-config interface all'
    config_get_token: '/^interface <name>$/'

  description:
    config_get_token_append: '/^description (.*)$/'
    # config_get_token value for 'description' is now:
    # ['/^interface %s$/i', '/^description (.*)$/']
```

This can also be used to specify conditional tokens which may or may not be
used depending on the set of parameters passed into `config_get()`:

```yaml
bgp:
  _template:
    config_get: 'show running bgp all'
    config_get_token: '/^router bgp <asnum>$/'
    config_get_token_append:
      - '/^vrf <vrf>$/'

  router_id:
    config_get_token_append: '/^router-id (\S+)$/'
```

In this example, both `config_get('bgp', 'router_id', {:asnum => '1'})` and
`config_get('bgp', 'router_id', {:asnum => '1', :vrf => 'red'})` are valid -
the former will match 'router bgp 1' followed by 'router-id', while the latter
will match 'router bgp 1' followed by 'vrf red' followed by 'router-id'.

### `config_set`

The `config_set` parameter is a string or array of strings representing the
configuration CLI command(s) used to set the value of the attribute.

```yaml
interface:
  create:
    config_set: 'interface <name>'

  description:
    config_set: ['interface <name>', 'description <desc>']
```

### `config_set_append`

When using a `_template` section, an attribute can use `config_set_append` to
extend the `config_set` value provided by the template instead of replacing it:

```yaml
interface:
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
bgp:
  _template:
    config_set: 'router bgp <asnum>'
    config_set_append:
      - 'vrf <vrf>'
```

### `default_value`

If there is a default value for this attribute when not otherwise specified by
the user, the `default_value` parameter describes it. This can be a string,
boolean, integer, or array.

```yaml
interface:
  description:
    default_value: ''

interface_ospf:
  hello_interval:
    default_value: 10

ospf:
  auto_cost:
    default_value: [40, 'Gbps']
```

### `test_config_get` and `test_config_get_regex`

Test-only equivalents to `config_get` and `config_get_token` - a show command
to be executed over telnet by the minitest unit test scripts, and a regex
(or array thereof) to match in the resulting plaintext output.
Should only be referenced by test scripts, never by a feature provider itself.

```yaml
show_version:
  boot_image:
    test_config_get: 'show version | no-more'
    test_config_get_regex: '/NXOS image file is: (.*)$/'
```

### `test_config_result`

Test-only container for input-result pairs that might differ by platform.
Should only be referenced by test scripts, never by a feature provider itself.

```yaml
vtp:
  version:
    test_config_result:
      3: 'Cisco::CliError'
```

## Style Guide

Please keep all feature names in alphabetical order, and all options under a
feature in alphabetical order as well. As YAML permits duplicate entries
(in which case the last entry overrides any earlier entries), keeping a
consistent order helps to prevent accidentally introducing such duplication.

Note that `~` is the YAML syntax that corresponds to Ruby's `nil`.

Use the key-value wildcarding style wherever possible, as it's more flexible
than the printf-style wildcarding.
