Changelog
=========

(unreleased)
------------

* Improved logic in Vtp class to handle the presence or absence of
  'feature vtp' and 'vtp domain' configuration.
* Fixed missing `default_timer_throttle_*` APIs in RouterOspfVrf class.
* Fixed idempotency and area update issues in interface_ospf class.
* Updated CliError class definition to make it easier to troubleshoot such
  errors when running Puppet modules that use this gem.

0.9.0
-----

* First public release, corresponding to Early Field Trial (EFT) of
  Cisco NX-OS 7.0(3)I2(1).
