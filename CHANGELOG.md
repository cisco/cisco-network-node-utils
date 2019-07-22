Changelog
=========

## Unreleased

### Added

### Changed

### Removed
- Removal of deprecated `interface` `private-vlan` properties.

| Deprecated/Removed Name | New Name |
|:---|:---|
| `private_vlan_mapping`                          | `pvlan_mapping`
| `switchport_mode_private_vlan_host`             | `switchport_pvlan_host`, `switchport_pvlan_promiscuous`,
| `switchport_mode_private_vlan_host_association` | `switchport_pvlan_host_association`
| `switchport_mode_private_vlan_host_promiscous`  | `switchport_pvlan_mapping`
| `switchport_mode_private_vlan_trunk_promiscuous`| `switchport_pvlan_trunk_promiscuous`
| `switchport_mode_private_vlan_trunk_secondary`  | `switchport_pvlan_trunk_secondary`
| `switchport_private_vlan_association_trunk`     | `switchport_pvlan_trunk_association`
| `switchport_private_vlan_mapping_trunk`         | `switchport_pvlan_mapping_trunk`
| `switchport_private_vlan_trunk_allowed_vlan`    | `switchport_pvlan_trunk_allowed_vlan`
| `switchport_private_vlan_trunk_native_vlan`     | `switchport_pvlan_trunk_native_vlan`

- Removal of deprecated `vlan` `private-vlan` properties.

| Deprecated/Removed Name | New Name |
|:---|:---|
| `private_vlan_association` | `pvlan_association`
| `private_vlan_type`        | `pvlan_type`

### Issues Addressed

## [v2.0.2]

### Issues Addressed
* Fixes `Error: Could not retrieve local facts: [Cisco::Vdc]` on some N7k platforms

## [v2.0.1]

### Issues Addressed
* `facter` may raise when `show install patches` in some environments

## [v2.0.0]

### New Cisco Resources

### Added
* Extend nxapi client for https support
   * `use_ssl` will be true when `transport` is `https`
   * now makes use of `port` for custom nxapi ports
* Extend router_ospf_vrf with attribute:
   * `redistribute`
* `reset_instance` method to node. Allows a single instance of nodeutils to reset the environment cache.
* Extend vxlan_vtep_vni with attribute:
  * `suppress_arp_disable`
* Extend vxlan_vtep with attributes:
  * `global_suppress_arp`
  * `global_ingress_replication_bgp`
  * `global_mcast_group_l2`
  * `global_mcast_group_l3`

### Removed
  * Removed cache in `node_util.node`, which gave every inheriting class it's own cache.

### Changed

## [v1.10.0]

### New Cisco Resources

### Added
* Added syslog_facility with attribute:
  * `level`
* Extend syslog_server with attribute:
  * `facility`
* Extend interface with attributes:
   * `ipv6_redirects`
* Extend ace with attributes:
   * `proto_option`
   * `vlan`
   * `set_erspan_dscp`
   * `set_erspan_gre_proto`
* Extend network_dns with attributes:
  * `hostname`
* Added ability to specify environment at run time

Example:
```ruby
env = { host: '192.168.1.1', port: nil, username: 'admin', password: 'admin123', cookie: nil }
Cisco::Environment.add_env('default', env)
```

### Changed

### Removed

### Issues Addressed
* Removed default values for authentication in `interface_hsrp_group`

## [v1.9.0]

### New Cisco Resources
* EVPN Multisite
  * evpn_multisite (@rahushen)
  * evpn_stormcontrol (@rahushen)
  * interface_evpn_multisite (@rahushen)

* TRM
  * evpn_multicast (@rahushen)
  * ip_multicast (@rahushen)

### Added
* Extend vxlan_vtep with attributes:
   * `multisite_border_gateway_interface`

* Extend vxlan_vtep_vni with attributes:
   * `multisite_ingress_replication`

* Extend bgp_neighbor with attributes:
   * `peer_type`

* Extend bgp_neighbor_af with attributes:
   * `rewrite_evpn_rt_asn`

* Extend vrf_af with attributes:
   * `route_target_both_auto_mvpn`
   * `route_target_export_mvpn`
   * `route_target_import_mvpn`

* Extend feature with attributes:
  * `ngmvpn_enable`
  * `ngmvpn_disable`
  * `ngmvpn_enabled?`

### Changed

### Removed

### Issues Addressed

## [v1.8.0]

### New Cisco Resources
* ObjectGroup
  * object_group (@saichint)
  * object_group_entry (@saichint)

### Added
* Extend syslog_server with attributes:
   * `port`
* Extend syslog_settings with attributes:
  * `console`
  * `monitor`
  * `source_interface`
* Extend radius_global with attributes:
   * `source_interface`
* Extend tacacs_global with attributes:
  * `source_interface`

### Changed
* syslog_server initialize now uses options hash
 * Prior to this release syslog_server accepted positional arguments for name,
 level, and vrf.  New behavior is to pass attributes as a hash.

 Example:
 ```
 options = { 'name' => '1.1.1.1', 'level' => '4', 'port' => '2154',
             'vrf' => 'red' }
 Cisco::SyslogServer.new(options, true)
 ```
* tacacs_global key removal fixed
  * Prior to this release key removal was done by passing in a value of 8.  A
  nil value is now used.  Added intelligence to determine key format
  automatically for removal.

## [v1.7.0]

### New feature support

#### Cisco Resources
* span_session (@tomcooperca)
* bgp_af_aggr_addr (@saichint)

### Added
* Extend vpc with attributes:
   * `peer_switch`
   * `arp_synchronize`
   * `nd_synchronize`

* Extend interface with attributes:
   * `purge_config`

* Extend interface_channel_group with attributes:
   * `channel_group_mode`

* Extend ntp_config with attributes:
  * `authenticate`
  * `trusted_key`

* Extend ntp_server with attributes:
  * `key`
  * `maxpoll`
  * `minpoll`
  * `vrf`

* Added ntp_auth_key with attributes:
  * `algorithm`
  * `key`
  * `mode`
  * `password`

* Extend upgrade with attributes:
   * `package`

### Changed
* ntp_server initialize now uses options hash
  * Prior to this release ntp_server accepted positional arguments for id and
  prefer.  New behavior is to pass attributes as a hash.

  Example:
  ```
  options = { 'name' => id, 'key' => '999', 'prefer' => 'true',
              'minpoll' => '5', 'maxpoll' => '8', 'vrf' => 'red' }
  Cisco::NtpServer.new(options, true)
  ```

* Modified upgrade to support additional URI

* Modified upgrade attribute to drop version check

### Removed

### Resolved Issues

## [v1.6.0]

### New feature support

#### Cisco Resources
* Route_map
  * route_map (@saichint)

* Upgrade
  * upgrade (@rahushen)

### Added

* Extend interface with attributes:
   * `load_interval_counter_1_delay`
   * `load_interval_counter_2_delay`
   * `load_interval_counter_3_delay`

### Changed

### Removed

## [v1.5.0]

### New feature support
* Drill down capability into structured table output using command reference yaml (@mikewiebe)

#### Cisco Resources
* Hot Standby Router Protocol
  * hsrp_global (@saichint)
  * interface_hsrp_group (@saichint)

### Added

* Extend interface with attributes:
   * `hsrp_bfd`
   * `hsrp_delay_minimum`
   * `hsrp_delay_reload`
   * `hsrp_mac_refresh`
   * `hsrp_use_bia`
   * `hsrp_version`
   * `pim_bfd`
* Extend pim with attributes:
   * `bfd`
* Added support for Cisco NX-OS software releases `7.3(0)F1(1)` and `8.0(1)`

### Changed

### Removed

## [v1.4.1]

### Added

* Extend bgp with attributes:
   * `event_history_errors`
   * `event_history_objstore`
* Added support for Cisco NX-OS software release `7.3(0)I5(1)`

## [v1.4.0]

### New feature support

#### Cisco Resources
* Bidirectional Forwarding Detection
  * bfd (@saichint)
* Dynamic Host Configuration Protocol
  * dhcp_relay_global (@saichint)
* OSPF
  * ospf_area (@saichint)
  * ospf_area_vlink (@saichint)

### Added

* Extend interface with attributes:
   * `bfd_echo`
   * `ipv4_dhcp_relay_addr`
   * `ipv4_dhcp_relay_info_trust`
   * `ipv4_dhcp_relay_src_addr_hsrp`
   * `ipv4_dhcp_relay_src_intf`
   * `ipv4_dhcp_relay_subnet_broadcast`
   * `ipv4_dhcp_smart_relay`
   * `ipv6_dhcp_relay_addr`
   * `ipv6_dhcp_relay_src_intf`
   * `storm_control_broadcast`
   * `storm_control_multicast`
   * `storm_control_unicast`
* Extend interface_ospf with attributes:
   * `bfd`
   * `mtu_ignore`
   * `network_type`
   * `priority`
   * `shutdown`
   * `transmit_delay`
* Extend interface_portchannel with attributes:
   * `bfd_per_link`
* Extend router_ospf_vrf with attributes:
   * `bfd`
* Extend bgp_neighbor with attributes:
   * `bfd`
* Cisco Nexus 8xxx platform support added to existing classes

### Changed
* Deprecated `vlan` private-vlan properties and replaced with new methods. New file `vlan_DEPRECATED.rb` has been created to store the deprecated methods. The old -> new properties are:

| Old Name | New Name(s) |
|:---|:---:|
| `private_vlan_association`                      | `pvlan_association`
| `private_vlan_type`                             | `pvlan_type`

* Deprecated `interface` private-vlan properties and replaced with new methods. New files `interface_DEPRECATED.rb` and `DEPRECATED.yaml` have been created to store the deprecated methods. The old -> new properties are:

| Old Name | New Name(s) |
|:---|:---:|
| `private_vlan_mapping`                          | `pvlan_mapping`
| `switchport_mode_private_vlan_host`             | `switchport_pvlan_host`, `switchport_pvlan_promiscuous`,
| `switchport_mode_private_vlan_host_association` | `switchport_pvlan_host_association`
| `switchport_mode_private_vlan_host_promiscous`  | `switchport_pvlan_mapping`
| `switchport_mode_private_vlan_trunk_promiscuous`| `switchport_pvlan_trunk_promiscuous`
| `switchport_mode_private_vlan_trunk_secondary`  | `switchport_pvlan_trunk_secondary`
| `switchport_private_vlan_association_trunk`     | `switchport_pvlan_trunk_association`
| `switchport_private_vlan_mapping_trunk`         | `switchport_pvlan_mapping_trunk`
| `switchport_private_vlan_trunk_allowed_vlan`    | `switchport_pvlan_trunk_allowed_vlan`
| `switchport_private_vlan_trunk_native_vlan`     | `switchport_pvlan_trunk_native_vlan`

## [v1.3.0]

### New feature support

#### Cisco Resources
* Itd
  * itd_device_group (@saichint)
  * itd_device_group_node (@saichint)
  * itd_service (@saichint)
* Spanning Tree
  * stp_global (@saichint)
* Bridge Domain
  * bridge_domain (@rkorlepa)
  * bridge_domain_vni (@rkorlepa)
* Encapsulation Profile
  * vni_encapsulation_profile (@rkorlepa)

#### NetDev Resources
*

### Added

* Added a new property fabric-control for vlan MT-FULL fabricpath
* Added support for bdi interfaces to interface provider.
* Added a new node util to handle bridge domain range cli for member vni
* Added Bridge Domain, VNI and encapsulation profile node utils for MT-FULL on Nexus 7k.
* Minitests can declare the YAML feature they are exercising, and if the feature is `_exclude`d on the node under test, the test case will automatically be skipped in full.
* CliErrors raised by any `NodeUtil` subclass or instance will automatically prepend the `to_s` method output to make troubleshooting easier.
* `test_feature` minitest
* Extend interface with attributes:
  * `ipv4_forwarding`
  * `stp_bpdufilter`, `stp_bpduguard`, `stp_cost`, `stp_guard`, `stp_link_type`, `stp_mst_cost`
  * `stp_mst_port_priority`, `stp_port_priority`, `stp_port_type`, `stp_vlan_cost`, `stp_vlan_port_priority`
  * `switchport_private_vlan_trunk_allowed_vlan`, `switchport_private_vlan_trunk_native_vlan`
  * `switchport_mode_private_vlan_host`, `switchport_mode_private_vlan_host_association`
  * `switchport_mode_private_vlan_host_promiscous`, `switchport_mode_private_vlan_trunk_promiscous`, `switchport_mode_private_vlan_trunk_secondary`
  * `switchport_private_vlan_association_trunk`, `switchport_private_vlan_mapping_trunk`
  * `private_vlan_mapping`
* Extend Feature class with a class method to list feature compatible interfaces
* Extend vdc with interface_membership methods
* Extend vpc with vpc+ attributes on Nexus 5k/6k/7k:
  * `fabricpath_emulated_switch_id`
  * `fabricpath_multicast_load_balance` (only on Nexus 7k)
  * `port_channel_limit` (only on Nexus 7k)
* Extend vlan with attributes:
  * `private_vlan_association`, `private_vlan_type`
* Added N3k native support for portchannel_global

### Changed

* Major refactor and enhancement of `CommandReference` YAML files:
  - Filtering by platform is now by platform name only.
  - Replaced `config_get(_token)?(_append)?` with `get_command`, `get_context`, and `get_value`
  - Replaced `config_set(_append)?` with `set_context`, and `set_value`
  - Individual token values can be explicitly marked as optional (e.g., VRF context); tokens not marked as optional are mandatory.
  - Data format (CLI, NXAPI structured) is now assumed to be CLI unless explicitly specified otherwise using the new `(get_|set_)?data_format` YAML key. No more guessing based on whether a key looks like a hash key or a Regexp.
* `cisco_nxapi` Gem is no longer a dependency as the NXAPI client code has been merged into this Gem under the `Cisco::Client` namespace.
* Improved minitest logging CLI.
  - `ruby test_foo.rb -l debug` instead of `ruby test_foo.rb -- <host> <user> <pass> debug`
  - `rake test TESTOPTS='--log-level=debug'`
* Client connectivity is now specified in `/etc/cisco_node_utils.yaml` or `~/cisco_node_utils.yaml` instead of environment variables or command-line arguments to minitest.
  - `ruby test_foo.rb -e <node name defined in YAML>`
  - `rake test TESTOPTS='--environment=default'`

### Fixed

* Interface:
  - Correctly restore IP address when changing VRF membership
  - MTU is not supported on loopback interfaces

### Removed
* Removed `Node.lazy_connect` internal API.
* Removed `vni` node util class

## [v1.2.0]

### New feature support
* ACL (platforms: Nexus 3k and Nexus 9k)
  * acl (@saqibraza)
  * ace (@yjyongz)
  * remark ace (@bansalpradeep)
* EVPN (platforms: Nexus 3k and Nexus 9k)
  * evpn_vni (@andish)
* Fabric Path (platforms: Nexus 7k)
  * fabricpath_global (@dcheriancisco)
  * fabricpath_topology (@dcheriancisco)
* Feature
  * feature (@robert-w-gries)
* Interface (platforms: Nexus 3k, Nexus 5k, Nexus 6k, Nexus 7k and Nexus 9k)
  * interface_channel_group (@chrisvanheuveln)
  * interface_portchannel (@saichint)
  * interface_service_vni (@chrisvanheuveln)
* PIM (platforms: Nexus 3k and Nexus 9k)
  * pim (@smigopal)
  * pim_group_list (@smigopal)
  * pim_rp_address (@smigopal)
* Port Channel (platforms: Nexus 3k, Nexus 5k, Nexus 6k, Nexus 7k and Nexus 9k)
  * interface_channel_group (@chrisvanheuveln)
  * interface_portchannel (@saichint)
  * portchannel_global (@saichint)
* SNMP (platforms: Nexus 3k, Nexus 5k, Nexus 6k, Nexus 7k and Nexus 9k)
  * snmpnotification (@tphoney)
* VDC (platforms: Nexus 7k)
  * vdc (@chrisvanheuveln)
* VPC (platforms: Nexus 3k, Nexus 5k, Nexus 6k, Nexus 7k and Nexus 9k)
  * vpc (@dcheriancisco)
* VRF (platforms: Nexus 3k, Nexus 5k, Nexus 6k, Nexus 7k and Nexus 9k)
  * vrf_af (@chrisvanheuveln)
* VXLAN (platforms: Nexus 9k)
  * overlay_global (@alok-aggarwal)
  * vxlan_vtep (@dcheriancisco)
  * vxlan_vtep_vni (@mikewiebe)


### Additional platform support added to existing classes
#### Cisco Nexus 56xx, 60xx and 7xxx
* AAA
  * aaa_authentication_login
  * aaa_authentication_login_service
  * aaa_authentication_service
* BGP
  * bgp
  * bgp_af
  * bgp_af_neighobr
  * bgp_neighbor_af
* COMMAND_CONFIG
  * command_config (config_parser)
* DOMAIN
  * dns_domain
  * domain_name
  * name_server
* INTERFACE
  * interface
* NTP
  * ntp_config
  * ntp_server
* OSPF
  * interface_ospf
  * ospf
  * ospf_vrf
* RADIUS
  * radius_global
* SNMP
  * snmp_community
  * snmp_group
  * snmp_notification_receiver
  * snmp_server
  * snmp_user
* SYSLOG
  * syslog_server
  * syslog_setting
* TACACS
  * tacacs_server
  * tacacs_server_group
  * tacacs_server_host
* VLAN
  * vlan

### Added

* `Cisco::UnsupportedError` exception class, raised when a command is explicitly marked as unsupported on a particular class of nodes.
* Extend bgp with attributes:
  * `disable_policy_batching`, `disable_policy_batching_ipv4`, `disable_policy_batching_ipv6`
  * `event_history_cli`, `event_history_detail`, `event_history_events`, `event_history_periodic`
  * `fast_external_fallover`
  * `flush_routes`
  * `isolate`
  * `neighbor_down_fib_accelerate`
  * `route_distinguisher`
* Extend bgp_af with attributes:
  * `default_metric`
  * `distance_ebgp`, `distance_ibgp`, `distance_local`
  * `inject_map`
  * `suppress_inactive`
  * `table_map`
* Extend interface with attributes:
  * `fabric_forwarding_anycast_gateway`
  * `ipv4_acl_in`, `ipv4_acl_out`, `ipv6_acl_in`, `ipv6_acl_out`
  * `ipv4_address_secondary`, `ipv4_arp_timeout`
  * `vlan_mapping`
  * `vpc_id`, `vpc_peer_link`
  * switchport mode `fabricpath`
* Extend vrf with attributes:
  * `mhost_ipv4`
  * `mhost_ipv6`
  * `remote_route_filtering`
  * `vni`
  * `vpn_id`
* Extend vlan with attribute:
  * `mode`

### Changed

* Major refactor and enhancement of `CommandReference` YAML files:
  - Added support for `auto_default`, `default_only`, `kind`, and `multiple`
  - Added filtering by product ID (`/N7K/`) and by client type (`cli_nexus`)
  - `CommandReference` methods that do key-value style wildcard substitution now raise an `ArgumentError` if the result is empty (because not enough parameters were supplied).

## [v1.1.0]

### New feature support
* BGP
  * bgp (@mikewiebe)
  * bgp_af (@richwellum)
  * bgp_neighbor (@jyang09)
  * bgp_neighbor_af (@chrisvanheuveln)
* NTP
  * ntp_config (@jonnytpuppet)
  * ntp_server (@jonnytpuppet)
* RADIUS
  * radius_global (@jonnytpuppet)
  * radius_server (@jonnytpuppet)
* SNMP
  * snmp_notification_receiver (@jonnytpuppet)
* SYSLOG
  * syslog_server (@jonnytpuppet)
  * syslog_setting (@jonnytpuppet)
* Miscellaneous
  * dns_domain (@hunner)
  * domain_name (@bmjen)
  * name_server (@hunner)
  * network_snmp (@jonnytpuppet)

### Added

* Enabled [Travis-CI](https://travis-ci.org) integration to automatically run [rubocop](https://github.com/bbatsov/rubocop). Fixed all baseline rubocop warnings.
* Added git hooks to streamline certain processes:
  * Validate commit message format for consistency
  * Don't allow commit of code failing RuboCop `--lint` checks
  * If RuboCop is failing any check, warn on commit (but don't fail), and fail on push.
  * Don't allow push without updating CHANGELOG.md
  * Once git hooks are installed, automatically update them on pull/merge (if possible).
  * If using [git-flow]:
    * `git flow release start` and `git flow hotfix start` will automatically update `CHANGELOG.md` and `version.rb` for the new release version
    * `git flow release finish` will automatically bump the version number for the develop branch.
* Minitest enhancements:
  * Code coverage calculation using [SimpleCov]
  * Full Minitest suite can be run by `rake test`
  * UUT can be specified by the `NODE` environment variable or at runtime, in addition to the classic method of command line arguments to `ruby test_my_file.rb`
  * Added `config` and `(assert|refute)_show_match` helper methods for testing.
* Added `bin/check_metric_limits.rb` helper script in support of refactoring.
* Added best practices development guide.
* Added support for radius_global (@jonnytpuppet)
* Added support for radius_server_group (@jonnytpuppet)

### Fixed

* Fixed several bugs in `SnmpUser.(auth|priv)_password_equal?`
* Fixed a bug in `test_interface.rb` that was keeping it from properly exercising the `negotiate_auto` functionality.
* Added a cache_flush call in `Platform.chassis` to work around an infrequent issue.

### Changed

* Added missing steps to CONTRIBUTING.md and README-develop-node-utils-APIs.md
* Added git config comments
* Moved `platform_info.(rb|yaml)` from `lib/` to `tests/` as it is test-only code.
* Now requires Minitest ~> 5.0 instead of Minitest < 5.0.

### Removed

* Dropped support for Ruby 1.9.3 as it is end-of-life.
* Removed `test_all_cisco.rb` as `rake test` can auto-discover all tests.

## [v1.0.1]

* Updated to fix broken documentation links.

## [v1.0.0]

* Improved logic in Vtp class to handle the presence or absence of
  'feature vtp' and 'vtp domain' configuration.
* Fixed missing `default_timer_throttle_*` APIs in RouterOspfVrf class.
* Fixed idempotency and area update issues in interface_ospf class.
* Updated CliError class definition to make it easier to troubleshoot such
  errors when running Puppet modules that use this gem.
* Added dotted-decimal munging for the area getter in interface_ospf.
* Added n9000_sample*.rpm to /tests for use with minitests.
* Updated yum install method to include vrf, fixes minitest issue.
* Extended cisco_interface with the following attributes:
  * encapsulation dot1q
  * mtu
  * switchport trunk allowed and native vlans
  * vrf member
* Move misc READMEs into /docs

## 0.9.0

* First public release, corresponding to Early Field Trial (EFT) of
  Cisco NX-OS 7.0(3)I2(1).

[git-flow]: https://github.com/petervanderdoes/gitflow-avh
[SimpleCov]: https://github.com/colszowka/simplecov

[v2.0.2]: https://github.com/cisco/cisco-network-node-utils/compare/v2.0.1...v2.0.2
[v2.0.1]: https://github.com/cisco/cisco-network-node-utils/compare/v2.0.0...v2.0.1
[v2.0.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.10.0...v2.0.0
[v1.10.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.9.0...v1.10.0
[v1.9.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.8.0...v1.9.0
[v1.8.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.7.0...v1.8.0
[v1.7.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.6.0...v1.7.0
[v1.6.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.5.0...v1.6.0
[v1.5.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.4.1...v1.5.0
[v1.4.1]: https://github.com/cisco/cisco-network-node-utils/compare/v1.4.0...v1.4.1
[v1.4.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.0.1...v1.1.0
[v1.0.1]: https://github.com/cisco/cisco-network-node-utils/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/cisco/cisco-network-node-utils/compare/v0.9.0...v1.0.0
