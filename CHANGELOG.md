Changelog
=========

## [Unreleased]

### Added

* Enabled [Travis-CI](https://travis-ci.org) integration to automatically run [rubocop](https://github.com/bbatsov/rubocop). Fixed all baseline rubocop warnings.
* Added support for name_server (@jonnytpuppet)
* Added support for ntp_server (@hunner)
* Added git hooks to streamline certain processes:
  * Validate commit message format for consistency
  * Don't allow commit of code failing Rubocop lint checks
  * Don't allow push if Rubocop is failing any check
  * Don't allow push without updating CHANGELOG.md
  * Once git hooks are installed, automatically update them on pull/merge (if possible).
  * If using [git-flow]:
    * `git flow release start` and `git flow hotfix start` will automatically update `CHANGELOG.md` and `version.rb` for the new release version
    * `git flow release finish` will automatically bump the version number for the develop branch.

### Fixed

* Fixed a bug in SnmpUser.auth_password_equal? and SnmpUser.priv_password_equal? that reported incorrectly when the passwords are unset.
* Added missing steps to CONTRIBUTING.md and README-develop-node-utils-APIs.md

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

[unreleased]: https://github.com/cisco/cisco-network-node-utils/compare/master...develop
[v1.0.1]: https://github.com/cisco/cisco-network-node-utils/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/cisco/cisco-network-node-utils/compare/v0.9.0...v1.0.0

