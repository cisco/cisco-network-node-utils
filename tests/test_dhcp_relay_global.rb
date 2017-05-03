# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/dhcp_relay_global'

include Cisco
# TestDhcpRelayGlobal - Minitest for general functionality
# of the DhcpRelayGlobal class.
class TestDhcpRelayGlobal < CiscoTestCase
  @skip_unless_supported = 'dhcp_relay_global'
  DEFAULT_NAME = 'default'

  # Tests

  def setup
    super
    config_no_warn('no feature dhcp')
  end

  def teardown
    config_no_warn('no feature dhcp') if first_or_last_teardown
    super
  end

  def create_dhcp_relay_global
    DhcpRelayGlobal.new
  end

  def test_collection_empty
    drg = DhcpRelayGlobal.globals
    assert_empty(drg)
  end

  def test_destroy
    drg = create_dhcp_relay_global
    assert_equal(true, Feature.dhcp_enabled?)

    drg.destroy
    [:ipv4_information_option,
     :ipv4_information_option_trust,
     :ipv4_information_option_vpn,
     :ipv4_information_trust_all,
     :ipv4_relay,
     :ipv4_smart_relay,
     :ipv4_src_addr_hsrp,
     :ipv4_src_intf,
     :ipv4_sub_option_circuit_id_custom,
     :ipv4_sub_option_circuit_id_string,
     :ipv4_sub_option_cisco,
     :ipv6_option_cisco,
     :ipv6_option_vpn,
     :ipv6_relay,
     :ipv6_src_intf,
    ].each do |prop|
      assert_equal(drg.send("default_#{prop}"), drg.send("#{prop}")) if
        drg.send("#{prop}")
    end
  end

  def test_ipv4_information_option
    drg = create_dhcp_relay_global
    assert_equal(drg.default_ipv4_information_option, drg.ipv4_information_option)
    drg.ipv4_information_option = true
    assert_equal(true, drg.ipv4_information_option)
    drg.ipv4_information_option = drg.default_ipv4_information_option
    assert_equal(drg.default_ipv4_information_option, drg.ipv4_information_option)
  end

  def test_ipv4_information_option_trust
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'ipv4_information_option_trust')
      assert_nil(drg.ipv4_information_option_trust)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv4_information_option_trust = true
      end
      return
    end
    assert_equal(drg.default_ipv4_information_option_trust,
                 drg.ipv4_information_option_trust)
    drg.ipv4_information_option_trust = true
    assert_equal(true, drg.ipv4_information_option_trust)
    drg.ipv4_information_option_trust = drg.default_ipv4_information_option_trust
    assert_equal(drg.default_ipv4_information_option_trust,
                 drg.ipv4_information_option_trust)
  end

  def test_ipv4_information_option_vpn
    drg = create_dhcp_relay_global
    assert_equal(drg.default_ipv4_information_option_vpn,
                 drg.ipv4_information_option_vpn)
    drg.ipv4_information_option_vpn = true
    assert_equal(true, drg.ipv4_information_option_vpn)
    drg.ipv4_information_option_vpn = drg.default_ipv4_information_option_vpn
    assert_equal(drg.default_ipv4_information_option_vpn,
                 drg.ipv4_information_option_vpn)
  end

  def test_ipv4_information_trust_all
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'ipv4_information_trust_all')
      assert_nil(drg.ipv4_information_trust_all)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv4_information_trust_all = true
      end
      return
    end
    assert_equal(drg.default_ipv4_information_trust_all,
                 drg.ipv4_information_trust_all)
    drg.ipv4_information_trust_all = true
    assert_equal(true, drg.ipv4_information_trust_all)
    drg.ipv4_information_trust_all = drg.default_ipv4_information_trust_all
    assert_equal(drg.default_ipv4_information_trust_all,
                 drg.ipv4_information_trust_all)
  end

  def test_ipv4_relay
    drg = create_dhcp_relay_global
    assert_equal(drg.default_ipv4_relay, drg.ipv4_relay)
    drg.ipv4_relay = true
    assert_equal(true, drg.ipv4_relay)
    drg.ipv4_relay = false
    assert_equal(false, drg.ipv4_relay)
    drg.ipv4_relay = drg.default_ipv4_relay
    assert_equal(drg.default_ipv4_relay, drg.ipv4_relay)
  end

  def test_ipv4_smart_relay
    drg = create_dhcp_relay_global
    assert_equal(drg.default_ipv4_smart_relay, drg.ipv4_smart_relay)
    drg.ipv4_smart_relay = true
    assert_equal(true, drg.ipv4_smart_relay)
    drg.ipv4_smart_relay = drg.default_ipv4_smart_relay
    assert_equal(drg.default_ipv4_smart_relay, drg.ipv4_smart_relay)
  end

  def test_ipv4_src_addr_hsrp
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'ipv4_src_addr_hsrp')
      assert_nil(drg.ipv4_src_addr_hsrp)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv4_src_addr_hsrp = true
      end
      return
    end
    assert_equal(drg.default_ipv4_src_addr_hsrp,
                 drg.ipv4_src_addr_hsrp)
    drg.ipv4_src_addr_hsrp = true
    assert_equal(true, drg.ipv4_src_addr_hsrp)
    drg.ipv4_src_addr_hsrp = drg.default_ipv4_src_addr_hsrp
    assert_equal(drg.default_ipv4_src_addr_hsrp,
                 drg.ipv4_src_addr_hsrp)
  end

  def test_ipv4_src_intf
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global', 'ipv4_src_intf')
      assert_nil(drg.ipv4_src_intf)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv4_src_intf = 'port-channel200'
      end
      return
    end
    assert_equal(drg.default_ipv4_src_intf, drg.ipv4_src_intf)
    drg.ipv4_src_intf = 'port-channel200'
    assert_equal('port-channel200', drg.ipv4_src_intf)
    drg.ipv4_src_intf = drg.default_ipv4_src_intf
    assert_equal(drg.default_ipv4_src_intf, drg.ipv4_src_intf)
  end

  def test_ipv4_sub_option_circuit_id_custom
    skip_nexus_i2_image?
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'ipv4_sub_option_circuit_id_custom')
      assert_nil(drg.ipv4_sub_option_circuit_id_custom)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv4_sub_option_circuit_id_custom = true
      end
      return
    end
    assert_equal(drg.default_ipv4_sub_option_circuit_id_custom,
                 drg.ipv4_sub_option_circuit_id_custom)
    drg.ipv4_sub_option_circuit_id_custom = true
    assert_equal(true, drg.ipv4_sub_option_circuit_id_custom)
    drg.ipv4_sub_option_circuit_id_custom = drg.default_ipv4_sub_option_circuit_id_custom
    assert_equal(drg.default_ipv4_sub_option_circuit_id_custom,
                 drg.ipv4_sub_option_circuit_id_custom)
  end

  def test_ipv4_sub_option_circuit_id_string
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global', 'ipv4_sub_option_circuit_id_string')
      assert_nil(drg.ipv4_sub_option_circuit_id_string)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv4_sub_option_circuit_id_string = '%p%p'
      end
      return
    end
    skip_incompat_version?('dhcp_relay_global', 'ipv4_sub_option_circuit_id_string')
    assert_equal(drg.default_ipv4_sub_option_circuit_id_string, drg.ipv4_sub_option_circuit_id_string)
    str = '%p%p'
    drg.ipv4_sub_option_circuit_id_string = str
    assert_match(/#{str}/, drg.ipv4_sub_option_circuit_id_string)
    drg.ipv4_sub_option_circuit_id_string = drg.default_ipv4_sub_option_circuit_id_string
    assert_equal(drg.default_ipv4_sub_option_circuit_id_string, drg.ipv4_sub_option_circuit_id_string)
  end

  def test_ipv4_sub_option_cisco
    drg = create_dhcp_relay_global
    assert_equal(drg.default_ipv4_sub_option_cisco, drg.ipv4_sub_option_cisco)
    drg.ipv4_sub_option_cisco = true
    assert_equal(true, drg.ipv4_sub_option_cisco)
    drg.ipv4_sub_option_cisco = drg.default_ipv4_sub_option_cisco
    assert_equal(drg.default_ipv4_sub_option_cisco, drg.ipv4_sub_option_cisco)
  end

  def test_ipv6_option_cisco
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'ipv6_option_cisco')
      assert_nil(drg.ipv6_option_cisco)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv6_option_cisco = true
      end
      return
    end
    assert_equal(drg.default_ipv6_option_cisco,
                 drg.ipv6_option_cisco)
    drg.ipv6_option_cisco = true
    assert_equal(true, drg.ipv6_option_cisco)
    drg.ipv6_option_cisco = drg.default_ipv6_option_cisco
    assert_equal(drg.default_ipv6_option_cisco,
                 drg.ipv6_option_cisco)
  end

  def test_ipv6_option_vpn
    drg = create_dhcp_relay_global
    assert_equal(drg.default_ipv6_option_vpn, drg.ipv6_option_vpn)
    drg.ipv6_option_vpn = true
    assert_equal(true, drg.ipv6_option_vpn)
    drg.ipv6_option_vpn = drg.default_ipv6_option_vpn
    assert_equal(drg.default_ipv6_option_vpn, drg.ipv6_option_vpn)
  end

  def test_ipv6_relay
    drg = create_dhcp_relay_global
    assert_equal(drg.default_ipv6_relay, drg.ipv6_relay)
    drg.ipv6_relay = true
    assert_equal(true, drg.ipv6_relay)
    drg.ipv6_relay = false
    assert_equal(false, drg.ipv6_relay)
    drg.ipv6_relay = drg.default_ipv6_relay
    assert_equal(drg.default_ipv6_relay, drg.ipv6_relay)
  end

  def test_ipv6_src_intf
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global', 'ipv6_src_intf')
      assert_nil(drg.ipv6_src_intf)
      assert_raises(Cisco::UnsupportedError) do
        drg.ipv6_src_intf = 'loopback2'
      end
      return
    end
    assert_equal(drg.default_ipv6_src_intf, drg.ipv6_src_intf)
    drg.ipv6_src_intf = 'loopback2 '
    assert_equal('loopback2', drg.ipv6_src_intf)
    drg.ipv6_src_intf = drg.default_ipv6_src_intf
    assert_equal(drg.default_ipv6_src_intf, drg.ipv6_src_intf)
  end
end
