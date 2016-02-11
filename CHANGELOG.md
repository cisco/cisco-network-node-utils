Changelog
=========

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
  * `vni`
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

[v1.2.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/cisco/cisco-network-node-utils/compare/v1.0.1...v1.1.0
[v1.0.1]: https://github.com/cisco/cisco-network-node-utils/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/cisco/cisco-network-node-utils/compare/v0.9.0...v1.0.0

