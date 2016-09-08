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
    config_no_warn 'no feature dhcp'
  end

  def teardown
    config_no_warn('no feature dhcp') if first_or_last_teardown
    super
  end

  def create_dhcp_relay_global(name=DEFAULT_NAME)
    DhcpRelayGlobal.new(name)
  end

  def test_information_option
    drg = create_dhcp_relay_global
    assert_equal(drg.default_information_option, drg.information_option)
    drg.information_option = true
    assert_equal(true, drg.information_option)
    drg.information_option = drg.default_information_option
    assert_equal(drg.default_information_option, drg.information_option)
  end

  def test_information_option_trust
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'information_option_trust')
      assert_nil(drg.information_option_trust)
      assert_raises(Cisco::UnsupportedError) do
        drg.information_option_trust = true
      end
      return
    end
    assert_equal(drg.default_information_option_trust,
                 drg.information_option_trust)
    drg.information_option_trust = true
    assert_equal(true, drg.information_option_trust)
    drg.information_option_trust = drg.default_information_option_trust
    assert_equal(drg.default_information_option_trust,
                 drg.information_option_trust)
  end

  def test_information_option_vpn
    drg = create_dhcp_relay_global
    assert_equal(drg.default_information_option_vpn,
                 drg.information_option_vpn)
    drg.information_option_vpn = true
    assert_equal(true, drg.information_option_vpn)
    drg.information_option_vpn = drg.default_information_option_vpn
    assert_equal(drg.default_information_option_vpn,
                 drg.information_option_vpn)
  end

  def test_information_trust_all
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'information_trust_all')
      assert_nil(drg.information_trust_all)
      assert_raises(Cisco::UnsupportedError) do
        drg.information_trust_all = true
      end
      return
    end
    assert_equal(drg.default_information_trust_all,
                 drg.information_trust_all)
    drg.information_trust_all = true
    assert_equal(true, drg.information_trust_all)
    drg.information_trust_all = drg.default_information_trust_all
    assert_equal(drg.default_information_trust_all,
                 drg.information_trust_all)
  end

  def test_relay
    drg = create_dhcp_relay_global
    assert_equal(drg.default_relay, drg.relay)
    drg.relay = true
    assert_equal(true, drg.relay)
    drg.relay = false
    assert_equal(false, drg.relay)
    drg.relay = drg.default_relay
    assert_equal(drg.default_relay, drg.relay)
  end

  def test_smart_relay
    drg = create_dhcp_relay_global
    assert_equal(drg.default_smart_relay, drg.smart_relay)
    drg.smart_relay = true
    assert_equal(true, drg.smart_relay)
    drg.smart_relay = drg.default_smart_relay
    assert_equal(drg.default_smart_relay, drg.smart_relay)
  end

  def test_src_addr_hsrp
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'src_addr_hsrp')
      assert_nil(drg.src_addr_hsrp)
      assert_raises(Cisco::UnsupportedError) do
        drg.src_addr_hsrp = true
      end
      return
    end
    assert_equal(drg.default_src_addr_hsrp,
                 drg.src_addr_hsrp)
    drg.src_addr_hsrp = true
    assert_equal(true, drg.src_addr_hsrp)
    drg.src_addr_hsrp = drg.default_src_addr_hsrp
    assert_equal(drg.default_src_addr_hsrp,
                 drg.src_addr_hsrp)
  end

  def test_src_intf
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global', 'src_intf')
      assert_nil(drg.src_intf)
      assert_raises(Cisco::UnsupportedError) do
        drg.src_intf = 'port-channel200'
      end
      return
    end
    assert_equal(drg.default_src_intf, drg.src_intf)
    drg.src_intf = 'port-channel200'
    assert_equal('port-channel200', drg.src_intf)
    drg.src_intf = drg.default_src_intf
    assert_equal(drg.default_src_intf, drg.src_intf)
  end

  # TODO: old n3k skip
  def test_sub_option_circuit_id_custom
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'sub_option_circuit_id_custom')
      assert_nil(drg.sub_option_circuit_id_custom)
      assert_raises(Cisco::UnsupportedError) do
        drg.sub_option_circuit_id_custom = true
      end
      return
    end
    assert_equal(drg.default_sub_option_circuit_id_custom,
                 drg.sub_option_circuit_id_custom)
    drg.sub_option_circuit_id_custom = true
    assert_equal(true, drg.sub_option_circuit_id_custom)
    drg.sub_option_circuit_id_custom = drg.default_sub_option_circuit_id_custom
    assert_equal(drg.default_sub_option_circuit_id_custom,
                 drg.sub_option_circuit_id_custom)
  end

  def test_sub_option_cisco
    drg = create_dhcp_relay_global
    assert_equal(drg.default_sub_option_cisco, drg.sub_option_cisco)
    drg.sub_option_cisco = true
    assert_equal(true, drg.sub_option_cisco)
    drg.sub_option_cisco = drg.default_sub_option_cisco
    assert_equal(drg.default_sub_option_cisco, drg.sub_option_cisco)
  end

  def test_v6_option_cisco
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global',
                                   'v6_option_cisco')
      assert_nil(drg.v6_option_cisco)
      assert_raises(Cisco::UnsupportedError) do
        drg.v6_option_cisco = true
      end
      return
    end
    assert_equal(drg.default_v6_option_cisco,
                 drg.v6_option_cisco)
    drg.v6_option_cisco = true
    assert_equal(true, drg.v6_option_cisco)
    drg.v6_option_cisco = drg.default_v6_option_cisco
    assert_equal(drg.default_v6_option_cisco,
                 drg.v6_option_cisco)
  end

  def test_v6_option_vpn
    drg = create_dhcp_relay_global
    assert_equal(drg.default_v6_option_vpn, drg.v6_option_vpn)
    drg.v6_option_vpn = true
    assert_equal(true, drg.v6_option_vpn)
    drg.v6_option_vpn = drg.default_v6_option_vpn
    assert_equal(drg.default_v6_option_vpn, drg.v6_option_vpn)
  end

  def test_v6_relay
    drg = create_dhcp_relay_global
    assert_equal(drg.default_v6_relay, drg.v6_relay)
    drg.v6_relay = true
    assert_equal(true, drg.v6_relay)
    drg.v6_relay = false
    assert_equal(false, drg.v6_relay)
    drg.v6_relay = drg.default_v6_relay
    assert_equal(drg.default_v6_relay, drg.v6_relay)
  end

  def test_v6_src_intf
    drg = create_dhcp_relay_global
    if validate_property_excluded?('dhcp_relay_global', 'v6_src_intf')
      assert_nil(drg.v6_src_intf)
      assert_raises(Cisco::UnsupportedError) do
        drg.v6_src_intf = 'loopback2'
      end
      return
    end
    assert_equal(drg.default_v6_src_intf, drg.v6_src_intf)
    drg.v6_src_intf = 'loopback2 '
    assert_equal('loopback2', drg.v6_src_intf)
    drg.v6_src_intf = drg.default_v6_src_intf
    assert_equal(drg.default_v6_src_intf, drg.v6_src_intf)
  end
end
