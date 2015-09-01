Changelog
=========

Unreleased
----------

* Fixed a bug in SnmpUser.auth_password_equal? and SnmpUser.priv_password_equal? that reported incorrectly when the passwords are unset.

1.0.0
-----

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

0.9.0
-----

* First public release, corresponding to Early Field Trial (EFT) of
  Cisco NX-OS 7.0(3)I2(1).
