# Copyright (c) 2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/interface_hsrp_group'

# TestInterfaceHsrpGroup - Minitest for InterfaceHsrpGroup
# node utility class
class TestInterfaceHsrpGroup < CiscoTestCase
  @skip_unless_supported = 'interface_hsrp_group'

  def setup
    super
    config_no_warn('no feature hsrp')
    config_no_warn('no interface Po100')
  end

  def teardown
    if first_or_last_teardown
      config_no_warn('no interface Po100')
      config_no_warn('no feature hsrp')
    end
    super
  end

  def create_interface_hsrp_group_ipv4(name='port-channel100',
                                       group=1,
                                       iptype='ipv4')
    intf = Interface.new(name)
    intf.switchport_mode = :disabled
    InterfaceHsrpGroup.new(name, group, iptype)
  end

  def create_interface_hsrp_group_ipv6(name='port-channel100',
                                       group=3,
                                       iptype='ipv6')
    intf = Interface.new(name)
    intf.switchport_mode = :disabled
    intf.hsrp_version = 2
    InterfaceHsrpGroup.new(name, group, iptype)
  end

  def test_collection_size
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg1 = create_interface_hsrp_group_ipv4
    ihg2 = create_interface_hsrp_group_ipv4('port-channel100', 2, 'ipv4')
    ihg3 = create_interface_hsrp_group_ipv4('port-channel100', 3, 'ipv4')
    ihg4 = create_interface_hsrp_group_ipv6
    ihg5 = create_interface_hsrp_group_ipv6('port-channel10', 3, 'ipv6')
    ihg6 = create_interface_hsrp_group_ipv4('port-channel10', 100, 'ipv4')
    assert_equal(1, InterfaceHsrpGroup.groups['port-channel100']['1'].size)
    assert_equal(1, InterfaceHsrpGroup.groups['port-channel100']['2'].size)
    assert_equal(2, InterfaceHsrpGroup.groups['port-channel100']['3'].size)
    assert_equal(1, InterfaceHsrpGroup.groups['port-channel10']['3'].size)
    assert_equal(1, InterfaceHsrpGroup.groups['port-channel10']['100'].size)
    ihg1.destroy
    ihg2.destroy
    ihg3.destroy
    ihg4.destroy
    ihg5.destroy
    ihg6.destroy
    assert_empty(InterfaceHsrpGroup.groups)
  end

  def test_group_name
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_group_name, ihg.group_name)
    ihg.group_name = 'hsrp_group_name'
    assert_equal('hsrp_group_name', ihg.group_name)
    ihg.group_name = ihg.default_group_name
    assert_equal(ihg.default_group_name, ihg.group_name)
    ihg = create_interface_hsrp_group_ipv6
    assert_equal(ihg.default_group_name, ihg.group_name)
    ihg.group_name = 'hsrp_group_name'
    assert_equal('hsrp_group_name', ihg.group_name)
    ihg.group_name = ihg.default_group_name
    assert_equal(ihg.default_group_name, ihg.group_name)
  end

  def test_mac_addr
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_mac_addr, ihg.mac_addr)
    ihg.mac_addr = '00:00:11:11:22:22'
    assert_equal('00:00:11:11:22:22', ihg.mac_addr)
    ihg.mac_addr = ihg.default_mac_addr
    assert_equal(ihg.default_mac_addr, ihg.mac_addr)
    ihg = create_interface_hsrp_group_ipv6
    assert_equal(ihg.default_mac_addr, ihg.mac_addr)
    ihg.mac_addr = '00:22:33:44:55:66'
    assert_equal('00:22:33:44:55:66', ihg.mac_addr)
    ihg.mac_addr = ihg.default_mac_addr
    assert_equal(ihg.default_mac_addr, ihg.mac_addr)
  end

  def test_auth_type_clear
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
    attrs = {}
    attrs[:authentication_auth_type] = 'cleartext'
    attrs[:authentication_string] = 'Test'
    ihg.authentication_set(attrs)
    assert_equal('cleartext', ihg.authentication_auth_type)
    assert_equal('Test', ihg.authentication_string)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)

    ihg = create_interface_hsrp_group_ipv6
    attrs[:authentication_auth_type] = 'cleartext'
    attrs[:authentication_string] = 'Test'
    ihg.authentication_set(attrs)
    assert_equal('cleartext', ihg.authentication_auth_type)
    assert_equal('Test', ihg.authentication_string)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_auth_type_md5
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    attrs = {}
    ihg = create_interface_hsrp_group_ipv4
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-chain'
    attrs[:authentication_string] = 'MyMD5Password'
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-chain', ihg.authentication_key_type)
    assert_equal('MyMD5Password', ihg.authentication_string)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
    ihg = create_interface_hsrp_group_ipv6
    attrs[:authentication_string] = 'MyMD5Password'
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-chain', ihg.authentication_key_type)
    assert_equal('MyMD5Password', ihg.authentication_string)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_auth_key_string_enc_0
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    attrs = {}
    ihg = create_interface_hsrp_group_ipv4
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-string'
    attrs[:authentication_enc_type] = '0'
    attrs[:authentication_string] = '7'
    attrs[:authentication_compatibility] = ihg.default_authentication_compatibility
    attrs[:authentication_timeout] = ihg.default_authentication_timeout
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('0', ihg.authentication_enc_type)
    assert_equal('7', ihg.authentication_string)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
    ihg = create_interface_hsrp_group_ipv6
    attrs[:authentication_string] = '7'
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('0', ihg.authentication_enc_type)
    assert_equal('7', ihg.authentication_string)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_auth_key_string_enc_7
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    attrs = {}
    ihg = create_interface_hsrp_group_ipv4
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-string'
    attrs[:authentication_enc_type] = '7'
    attrs[:authentication_string] = '12345678901234567890'
    attrs[:authentication_compatibility] = ihg.default_authentication_compatibility
    attrs[:authentication_timeout] = ihg.default_authentication_timeout
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('7', ihg.authentication_enc_type)
    assert_equal('12345678901234567890', ihg.authentication_string)
    ihg = create_interface_hsrp_group_ipv6
    attrs[:authentication_string] = '12345678901234567890'
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('7', ihg.authentication_enc_type)
    assert_equal('12345678901234567890', ihg.authentication_string)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_auth_key_string_enc_7_compat_timeout_ipv4
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    attrs = {}
    ihg = create_interface_hsrp_group_ipv4
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-string'
    attrs[:authentication_enc_type] = '7'
    attrs[:authentication_string] = '12345678901234567890'
    attrs[:authentication_compatibility] = ihg.default_authentication_compatibility
    attrs[:authentication_timeout] = ihg.default_authentication_timeout
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('7', ihg.authentication_enc_type)
    assert_equal('12345678901234567890', ihg.authentication_string)
    attrs[:authentication_compatibility] = true
    attrs[:authentication_timeout] = 6666
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('7', ihg.authentication_enc_type)
    assert_equal('12345678901234567890', ihg.authentication_string)
    assert_equal(true, ihg.authentication_compatibility)
    assert_equal(6666, ihg.authentication_timeout)
    attrs[:authentication_compatibility] = false
    ihg.authentication_set(attrs)
    assert_equal(false, ihg.authentication_compatibility)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_auth_key_string_enc_7_compat_timeout_ipv6
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    attrs = {}
    ihg = create_interface_hsrp_group_ipv6
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-string'
    attrs[:authentication_enc_type] = '7'
    attrs[:authentication_string] = '12345678901234567890'
    attrs[:authentication_compatibility] = ihg.default_authentication_compatibility
    attrs[:authentication_timeout] = ihg.default_authentication_timeout
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('7', ihg.authentication_enc_type)
    assert_equal('12345678901234567890', ihg.authentication_string)
    attrs[:authentication_compatibility] = true
    attrs[:authentication_timeout] = 6666
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('7', ihg.authentication_enc_type)
    assert_equal('12345678901234567890', ihg.authentication_string)
    assert_equal(true, ihg.authentication_compatibility)
    assert_equal(6666, ihg.authentication_timeout)
    attrs[:authentication_compatibility] = false
    ihg.authentication_set(attrs)
    assert_equal(false, ihg.authentication_compatibility)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_auth_key_string_enc_0_compat_timeout_ipv4
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    attrs = {}
    ihg = create_interface_hsrp_group_ipv4
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-string'
    attrs[:authentication_enc_type] = '0'
    attrs[:authentication_string] = 'MyUnEncr'
    attrs[:authentication_compatibility] = true
    attrs[:authentication_timeout] = 6666
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('0', ihg.authentication_enc_type)
    assert_equal('MyUnEncr', ihg.authentication_string)
    assert_equal(true, ihg.authentication_compatibility)
    assert_equal(6666, ihg.authentication_timeout)
    attrs[:authentication_compatibility] = false
    attrs[:authentication_timeout] = 3333
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('0', ihg.authentication_enc_type)
    assert_equal('MyUnEncr', ihg.authentication_string)
    assert_equal(false, ihg.authentication_compatibility)
    assert_equal(3333, ihg.authentication_timeout)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_auth_key_string_enc_0_compat_timeout_ipv6
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    attrs = {}
    ihg = create_interface_hsrp_group_ipv6
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-string'
    attrs[:authentication_enc_type] = '0'
    attrs[:authentication_string] = 'MyUnEncr'
    attrs[:authentication_compatibility] = true
    attrs[:authentication_timeout] = 6666
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('0', ihg.authentication_enc_type)
    assert_equal('MyUnEncr', ihg.authentication_string)
    assert_equal(true, ihg.authentication_compatibility)
    assert_equal(6666, ihg.authentication_timeout)
    attrs[:authentication_compatibility] = false
    attrs[:authentication_timeout] = 3333
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('0', ihg.authentication_enc_type)
    assert_equal('MyUnEncr', ihg.authentication_string)
    assert_equal(false, ihg.authentication_compatibility)
    assert_equal(3333, ihg.authentication_timeout)
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end

  def test_preempt_ipv4
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_preempt, ihg.preempt)
    assert_equal(ihg.default_preempt_delay_minimum, ihg.preempt_delay_minimum)
    assert_equal(ihg.default_preempt_delay_reload, ihg.preempt_delay_reload)
    assert_equal(ihg.default_preempt_delay_sync, ihg.preempt_delay_sync)
    delay = 100
    reload = 200
    sync = 300
    ihg.preempt_set(true, delay, reload, sync)
    assert_equal(true, ihg.preempt)
    assert_equal(100, ihg.preempt_delay_minimum)
    assert_equal(200, ihg.preempt_delay_reload)
    assert_equal(300, ihg.preempt_delay_sync)
    delay = 0
    reload = 0
    sync = 0
    ihg.preempt_set(true, delay, reload, sync)
    assert_equal(0, ihg.preempt_delay_minimum)
    assert_equal(0, ihg.preempt_delay_reload)
    assert_equal(0, ihg.preempt_delay_sync)
    ihg.preempt_set(ihg.default_preempt,
                    ihg.default_preempt_delay_minimum,
                    ihg.default_preempt_delay_reload,
                    ihg.default_preempt_delay_sync)
    assert_equal(ihg.default_preempt, ihg.preempt)
    assert_equal(ihg.default_preempt_delay_minimum, ihg.preempt_delay_minimum)
    assert_equal(ihg.default_preempt_delay_reload, ihg.preempt_delay_reload)
    assert_equal(ihg.default_preempt_delay_sync, ihg.preempt_delay_sync)
  end

  def test_preempt_ipv6
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv6
    assert_equal(ihg.default_preempt, ihg.preempt)
    assert_equal(ihg.default_preempt_delay_minimum, ihg.preempt_delay_minimum)
    assert_equal(ihg.default_preempt_delay_reload, ihg.preempt_delay_reload)
    assert_equal(ihg.default_preempt_delay_sync, ihg.preempt_delay_sync)
    delay = 222
    reload = 444
    sync = 666
    ihg.preempt_set(true, delay, reload, sync)
    assert_equal(true, ihg.preempt)
    assert_equal(222, ihg.preempt_delay_minimum)
    assert_equal(444, ihg.preempt_delay_reload)
    assert_equal(666, ihg.preempt_delay_sync)
    delay = 0
    reload = 0
    sync = 0
    ihg.preempt_set(true, delay, reload, sync)
    assert_equal(0, ihg.preempt_delay_minimum)
    assert_equal(0, ihg.preempt_delay_reload)
    assert_equal(0, ihg.preempt_delay_sync)
    ihg.preempt_set(ihg.default_preempt,
                    ihg.default_preempt_delay_minimum,
                    ihg.default_preempt_delay_reload,
                    ihg.default_preempt_delay_sync)
    assert_equal(ihg.default_preempt, ihg.preempt)
    assert_equal(ihg.default_preempt_delay_minimum, ihg.preempt_delay_minimum)
    assert_equal(ihg.default_preempt_delay_reload, ihg.preempt_delay_reload)
    assert_equal(ihg.default_preempt_delay_sync, ihg.preempt_delay_sync)
  end

  def test_priority_ipv4
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_priority, ihg.priority)
    assert_equal(ihg.default_priority_forward_thresh_lower,
                 ihg.priority_forward_thresh_lower)
    assert_equal(ihg.default_priority_forward_thresh_upper,
                 ihg.priority_forward_thresh_upper)
    ihg.priority_level_set(50, 10, 20)
    assert_equal(50, ihg.priority)
    assert_equal(10, ihg.priority_forward_thresh_lower)
    assert_equal(20, ihg.priority_forward_thresh_upper)
    ihg.priority_level_set(99,
                           ihg.default_priority_forward_thresh_lower,
                           ihg.default_priority_forward_thresh_upper)
    assert_equal(99, ihg.priority)
    assert_equal(ihg.default_priority_forward_thresh_lower,
                 ihg.priority_forward_thresh_lower)
    assert_equal(ihg.default_priority_forward_thresh_upper,
                 ihg.priority_forward_thresh_upper)
    ihg.priority_level_set(ihg.default_priority,
                           ihg.default_priority_forward_thresh_lower,
                           ihg.default_priority_forward_thresh_upper)
    assert_equal(ihg.default_priority, ihg.priority)
    assert_equal(ihg.default_priority_forward_thresh_lower,
                 ihg.priority_forward_thresh_lower)
    assert_equal(ihg.default_priority_forward_thresh_upper,
                 ihg.priority_forward_thresh_upper)
  end

  def test_priority_ipv6
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv6
    assert_equal(ihg.default_priority, ihg.priority)
    assert_equal(ihg.default_priority_forward_thresh_lower,
                 ihg.priority_forward_thresh_lower)
    assert_equal(ihg.default_priority_forward_thresh_upper,
                 ihg.priority_forward_thresh_upper)
    ihg.priority_level_set(44, 22, 33)
    assert_equal(44, ihg.priority)
    assert_equal(22, ihg.priority_forward_thresh_lower)
    assert_equal(33, ihg.priority_forward_thresh_upper)
    ihg.priority_level_set(155,
                           ihg.default_priority_forward_thresh_lower,
                           ihg.default_priority_forward_thresh_upper)
    assert_equal(155, ihg.priority)
    assert_equal(ihg.default_priority_forward_thresh_lower,
                 ihg.priority_forward_thresh_lower)
    assert_equal(ihg.default_priority_forward_thresh_upper,
                 ihg.priority_forward_thresh_upper)
    ihg.priority_level_set(ihg.default_priority,
                           ihg.default_priority_forward_thresh_lower,
                           ihg.default_priority_forward_thresh_upper)
    assert_equal(ihg.default_priority, ihg.priority)
    assert_equal(ihg.default_priority_forward_thresh_lower,
                 ihg.priority_forward_thresh_lower)
    assert_equal(ihg.default_priority_forward_thresh_upper,
                 ihg.priority_forward_thresh_upper)
  end

  def test_timers_ipv4
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_timers_hello, ihg.timers_hello)
    assert_equal(ihg.default_timers_hello_msec, ihg.timers_hello_msec)
    assert_equal(ihg.default_timers_hold, ihg.timers_hold)
    assert_equal(ihg.default_timers_hold_msec, ihg.timers_hold_msec)
    ihg.timers_set(ihg.default_timers_hello_msec,
                   10, ihg.default_timers_hold_msec, 50)
    assert_equal(10, ihg.timers_hello)
    assert_equal(ihg.default_timers_hello_msec, ihg.timers_hello_msec)
    assert_equal(50, ihg.timers_hold)
    assert_equal(ihg.default_timers_hold_msec, ihg.timers_hold_msec)
    ihg.timers_set(true, 500, true, 1500)
    assert_equal(500, ihg.timers_hello)
    assert_equal(true, ihg.timers_hello_msec)
    assert_equal(1500, ihg.timers_hold)
    assert_equal(true, ihg.timers_hold_msec)
    ihg.timers_set(true, 500, false, 5)
    assert_equal(500, ihg.timers_hello)
    assert_equal(true, ihg.timers_hello_msec)
    assert_equal(5, ihg.timers_hold)
    assert_equal(false, ihg.timers_hold_msec)
    ihg.timers_set(ihg.default_timers_hello_msec,
                   ihg.default_timers_hello,
                   ihg.default_timers_hold_msec,
                   ihg.default_timers_hold)
    assert_equal(ihg.default_timers_hello, ihg.timers_hello)
    assert_equal(ihg.default_timers_hello_msec, ihg.timers_hello_msec)
    assert_equal(ihg.default_timers_hold, ihg.timers_hold)
    assert_equal(ihg.default_timers_hold_msec, ihg.timers_hold_msec)
  end

  def test_timers_ipv6
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv6
    assert_equal(ihg.default_timers_hello, ihg.timers_hello)
    assert_equal(ihg.default_timers_hello_msec, ihg.timers_hello_msec)
    assert_equal(ihg.default_timers_hold, ihg.timers_hold)
    assert_equal(ihg.default_timers_hold_msec, ihg.timers_hold_msec)
    ihg.timers_set(ihg.default_timers_hello_msec,
                   20, ihg.default_timers_hold_msec, 100)
    assert_equal(20, ihg.timers_hello)
    assert_equal(ihg.default_timers_hello_msec, ihg.timers_hello_msec)
    assert_equal(100, ihg.timers_hold)
    assert_equal(ihg.default_timers_hold_msec, ihg.timers_hold_msec)
    ihg.timers_set(true, 300, true, 2000)
    assert_equal(300, ihg.timers_hello)
    assert_equal(true, ihg.timers_hello_msec)
    assert_equal(2000, ihg.timers_hold)
    assert_equal(true, ihg.timers_hold_msec)
    ihg.timers_set(true, 300, false, 10)
    assert_equal(300, ihg.timers_hello)
    assert_equal(true, ihg.timers_hello_msec)
    assert_equal(10, ihg.timers_hold)
    assert_equal(false, ihg.timers_hold_msec)
    ihg.timers_set(ihg.default_timers_hello_msec,
                   ihg.default_timers_hello,
                   ihg.default_timers_hold_msec,
                   ihg.default_timers_hold)
    assert_equal(ihg.default_timers_hello, ihg.timers_hello)
    assert_equal(ihg.default_timers_hello_msec, ihg.timers_hello_msec)
    assert_equal(ihg.default_timers_hold, ihg.timers_hold)
    assert_equal(ihg.default_timers_hold_msec, ihg.timers_hold_msec)
  end

  def test_ipv4_vip
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_ipv4_enable, ihg.ipv4_enable)
    assert_equal(ihg.default_ipv4_vip, ihg.ipv4_vip)
    ihg.ipv4_vip_set(true, ihg.default_ipv4_vip)
    assert_equal(true, ihg.ipv4_enable)
    assert_equal(ihg.default_ipv4_vip, ihg.ipv4_vip)
    ihg.ipv4_vip_set(true, '1.1.1.1')
    assert_equal(true, ihg.ipv4_enable)
    assert_equal('1.1.1.1', ihg.ipv4_vip)
    ihg.ipv4_vip_set(true, ihg.default_ipv4_vip)
    assert_equal(true, ihg.ipv4_enable)
    assert_equal(ihg.default_ipv4_vip, ihg.ipv4_vip)
    ihg.ipv4_vip_set(ihg.default_ipv4_enable, ihg.default_ipv4_vip)
    assert_equal(ihg.default_ipv4_enable, ihg.ipv4_enable)
    assert_equal(ihg.default_ipv4_vip, ihg.ipv4_vip)
    ihg.ipv4_vip_set(true, '1.1.1.1')
    ihg.ipv4_vip_set(ihg.default_ipv4_enable, ihg.default_ipv4_vip)
    assert_equal(ihg.default_ipv4_enable, ihg.ipv4_enable)
    assert_equal(ihg.default_ipv4_vip, ihg.ipv4_vip)
  end

  def test_ipv6_vip
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    config_no_warn('interface Po100 ; ipv6 address 2000::01/64')
    ihg = create_interface_hsrp_group_ipv6
    assert_equal(ihg.default_ipv6_vip, ihg.ipv6_vip)
    ihg.ipv6_vip = ['2000::11', '2000::55']
    assert_equal(['2000::11', '2000::55'], ihg.ipv6_vip)
    ihg.ipv6_vip = ihg.default_ipv6_vip
    assert_equal(ihg.default_ipv6_vip, ihg.ipv6_vip)
    assert_equal(ihg.default_ipv6_autoconfig, ihg.ipv6_autoconfig)
    ihg.ipv6_autoconfig = true
    assert_equal(true, ihg.ipv6_autoconfig)
    ihg.ipv6_autoconfig = ihg.default_ipv6_autoconfig
    assert_equal(ihg.default_ipv6_autoconfig, ihg.ipv6_autoconfig)
  end
end
