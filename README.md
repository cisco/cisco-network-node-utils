# CiscoNodeUtils - Cisco Node Utilities

The CiscoNodeUtils gem provides utilities for management of Cisco network
nodes. It is designed to work with Puppet and Chef as well as other
open source management tools. This release supports Cisco NX-OS nodes
running NX-OS 7.0(3)I2(1) and later.

## Installation

To install the CiscoNodeUtils, use the following command:

    $ gem install cisco_node_utils

(Add `sudo` if you're installing under a POSIX system as root)

Alternatively, if you've checked the source out directly, you can call
`rake install` from the root project directory.

## Examples

These utilities can be used directly on a Cisco device (as used by Puppet
and Chef) or can run on a workstation and point to a Cisco device (as used
by the included minitest suite).

### Usage on a Cisco device

```ruby
require 'cisco_node_utils'

# get a connection to the local device
node = Cisco::Node.instance()

version = node.config_get("show_version", "system_image")

node.config_set("vtp", "domain", "mycompany.com")
```

### Remote usage

```ruby
require 'cisco_node_utils'

Cisco::Node.lazy_connect = true

node = Cisco::Node.instance()
node.connect("n3k.mycompany.com", "username", "password")

version = node.config_get("show_version", "system_image")

node.config_set("vtp", "domain", "mycompany.com")
```

## Documentation

### Node

The `Node` class is a singleton which provides for management of a given Cisco
network node. It provides the base APIs `config_set`, `config_get`, and
`config_get_default`.

### CommandReference

The `CommandReference` module provides for the abstraction of NX-OS CLI,
especially to handle its variance between hardware platforms.
A series of YAML files are used to describe the CLI corresponding to a given
`(feature, attribute)` tuple for any given platform. When a `Node` is
connected, the platform identification of the Node is used to construct a
`CmdRef` object that corresponds to this platform. The `Node` APIs
`config_set`, `config_get`, and `config_get_default` all rely on the `CmdRef`.

See also [README_YAML](lib/cisco_node_utils/README_YAML.md).

### Feature Providers

Each feature supported by CiscoNodeUtils has its own class. For example,
`Cisco::RouterOspf` is the class used to manage OSPF router configuration on
a `Node`. Each feature class has getters and setters which are wrappers around
the Node APIs `config_set`, `config_get`, and `config_get_default`.

### Puppet and Chef

This library is designed as a shared backend between Puppet and Chef for the
management of Cisco nodes. Puppet providers and Chef providers alike can use
the feature provider classes from this module to do the majority of work in
actually managing device configuration and state. This reduces the amount of
code duplication between the Cisco Puppet modules and the Cisco Chef cookbooks.

Generally speaking, Puppet and Chef should only interact with the feature
provider classes, and not directly call into `CommandReference` or `Node`.

## Changelog

See [CHANGELOG](CHANGELOG.md) for a list of changes.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for developer and contributor guidelines.

## License

Copyright (c) 2013-2015 Cisco and/or its affiliates.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
