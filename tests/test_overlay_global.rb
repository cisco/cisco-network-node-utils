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
require_relative '../lib/cisco_node_utils/cisco_cmn_utils'
require_relative '../lib/cisco_node_utils/feature'
require_relative '../lib/cisco_node_utils/overlay_global'

include Cisco

# TestOverlayGlobal - Minitest for OverlayGlobal node utility
class TestOverlayGlobal < CiscoTestCase
  @skip_unless_supported = 'overlay_global'

  def setup
    super
    vdc_limit_f3_no_intf_needed(:set)
    config_no_warn('no feature fabric forwarding')
    config_no_warn('no nv overlay evpn')
  end

  def teardown
    config_no_warn('no feature fabric forwarding')
    config_no_warn('no nv overlay evpn')
    vdc_limit_f3_no_intf_needed(:clear) if first_or_last_teardown
  end

  def test_dup_host_ip_addr_detection
    o = OverlayGlobal.new
    if validate_property_excluded?('overlay_global',
                                   'dup_host_ip_addr_detection')
      assert_raises(Cisco::UnsupportedError) do
        o.dup_host_ip_addr_detection_set(200, 20)
      end
      return
    end

    assert_equal(o.default_dup_host_ip_addr_detection_host_moves,
                 o.dup_host_ip_addr_detection_host_moves)
    assert_equal(o.default_dup_host_ip_addr_detection_timeout,
                 o.dup_host_ip_addr_detection_timeout)

    # Set them to the default value and they should now be present
    default = [o.default_dup_host_ip_addr_detection_host_moves,
               o.default_dup_host_ip_addr_detection_timeout]
    o.dup_host_ip_addr_detection_set(*default)
    assert_equal(default[0], o.dup_host_ip_addr_detection_host_moves)
    assert_equal(default[1], o.dup_host_ip_addr_detection_timeout)
    assert(Feature.nv_overlay_evpn_enabled?)

    # Set them to non-default values
    val = [200, 20]
    o.dup_host_ip_addr_detection_set(*val)
    assert_equal(val, o.dup_host_ip_addr_detection)
    assert_equal(val[0], o.dup_host_ip_addr_detection_host_moves)
    assert_equal(val[1], o.dup_host_ip_addr_detection_timeout)
  end

  def test_dup_host_mac_detection
    o = OverlayGlobal.new

    skip_incompat_version?('overlay_global', 'dup_host_mac_detection')
    # Set to a non-default value
    val = [160, 16]
    o.dup_host_mac_detection_set(*val)
    assert_equal(val, o.dup_host_mac_detection)
    refute(Feature.nv_overlay_evpn_enabled?)

    # These properties always exist, even without 'nv overlay evpn'
    default = [o.default_dup_host_mac_detection_host_moves,
               o.default_dup_host_mac_detection_timeout]
    o.dup_host_mac_detection_set(*default)
    assert_equal(default, o.dup_host_mac_detection)
    refute(Feature.nv_overlay_evpn_enabled?)
  end

  def test_anycast_gateway_mac
    o = OverlayGlobal.new
    if validate_property_excluded?('overlay_global', 'anycast_gateway_mac')
      assert_raises(Cisco::UnsupportedError) { o.anycast_gateway_mac = '1.1.1' }
      return
    end

    assert_equal(o.default_anycast_gateway_mac, o.anycast_gateway_mac)

    # Explicitly set to default and it should be enabled
    o.anycast_gateway_mac = o.default_anycast_gateway_mac
    assert_equal(o.default_anycast_gateway_mac, o.anycast_gateway_mac)
    assert(Feature.nv_overlay_evpn_enabled?)

    # Set to various non-default values
    %w(1.1.1 55.a10.ffff 1223.3445.5668).each do |mac|
      o.anycast_gateway_mac = mac
      assert_equal(Utils.zero_pad_macaddr(mac), o.anycast_gateway_mac)
    end
  end
end
