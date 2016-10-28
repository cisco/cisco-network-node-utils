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
require_relative '../lib/cisco_node_utils/interface_hsrp'
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
    ih = InterfaceHsrp.new(name)
    ih.version = 2
    InterfaceHsrpGroup.new(name, group, iptype)
  end

  def test_collection_size
    ihg1 = create_interface_hsrp_group_ipv4
    ihg2 = create_interface_hsrp_group_ipv4('port-channel100', 2, 'ipv4')
    ihg3 = create_interface_hsrp_group_ipv4('port-channel100', 3, 'ipv4')
    ihg4 = create_interface_hsrp_group_ipv6
    ihg5 = create_interface_hsrp_group_ipv6('port-channel10', 3, 'ipv6')
    ihg6 = create_interface_hsrp_group_ipv4('port-channel10', 100, 'ipv4')
    assert_equal(1, InterfaceHsrpGroup.hsrp_groups['port-channel100']['1'].size)
    assert_equal(1, InterfaceHsrpGroup.hsrp_groups['port-channel100']['2'].size)
    assert_equal(2, InterfaceHsrpGroup.hsrp_groups['port-channel100']['3'].size)
    assert_equal(1, InterfaceHsrpGroup.hsrp_groups['port-channel10']['3'].size)
    assert_equal(1, InterfaceHsrpGroup.hsrp_groups['port-channel10']['100'].size)
    ihg1.destroy
    ihg2.destroy
    ihg3.destroy
    ihg4.destroy
    ihg5.destroy
    ihg6.destroy
    assert_empty(InterfaceHsrpGroup.hsrp_groups)
  end

  def test_name
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_name, ihg.name)
    ihg.name = 'hsrp_group_name'
    assert_equal('hsrp_group_name', ihg.name)
    ihg.name = ihg.default_name
    assert_equal(ihg.default_name, ihg.name)
    ihg = create_interface_hsrp_group_ipv6
    assert_equal(ihg.default_name, ihg.name)
    ihg.name = 'hsrp_group_name'
    assert_equal('hsrp_group_name', ihg.name)
    ihg.name = ihg.default_name
    assert_equal(ihg.default_name, ihg.name)
  end

  def test_mac_addr
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

  def test_authentication
    ihg = create_interface_hsrp_group_ipv4
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
    attrs = {}
    attrs[:authentication_auth_type] = ihg.default_authentication_auth_type
    attrs[:authentication_key_type] = ihg.default_authentication_key_type
    attrs[:authentication_enc_type] = ihg.default_authentication_enc_type
    attrs[:authentication_string] = ihg.default_authentication_string
    attrs[:authentication_compatibility] = ihg.default_authentication_compatibility
    attrs[:authentication_timeout] = ihg.default_authentication_timeout

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
    attrs[:authentication_auth_type] = 'md5'
    attrs[:authentication_key_type] = 'key-chain'
    attrs[:authentication_string] = 'MyMD5Password'
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-chain', ihg.authentication_key_type)
    assert_equal('MyMD5Password', ihg.authentication_string)
    attrs[:authentication_key_type] = 'key-string'
    attrs[:authentication_enc_type] = '0'
    attrs[:authentication_string] = '7'
    ihg.authentication_set(attrs)
    assert_equal('md5', ihg.authentication_auth_type)
    assert_equal('key-string', ihg.authentication_key_type)
    assert_equal('0', ihg.authentication_enc_type)
    assert_equal('7', ihg.authentication_string)
    attrs[:authentication_enc_type] = '7'
    attrs[:authentication_string] = '12345678901234567890'
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
    attrs[:authentication_string] = ihg.default_authentication_string
    ihg.authentication_set(attrs)
    assert_equal(ihg.default_authentication_string,
                 ihg.authentication_string)
  end
end
