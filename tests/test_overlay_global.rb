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
  def setup
    super
    config('no feature fabric forwarding')
    config('no nv overlay evpn')
    config('l2rib dup-host-mac-detection default')
  end

  def test_dup_host_ip_addr_detection
    overlay_global = OverlayGlobal.new

    # Before enabling 'nv overlay evpn', these properties do not exist
    assert_nil(overlay_global.dup_host_ip_addr_detection_host_moves)
    assert_nil(overlay_global.dup_host_ip_addr_detection_timeout)

    # Set them to the default value and they should now be present
    default = [overlay_global.default_dup_host_ip_addr_detection_host_moves,
               overlay_global.default_dup_host_ip_addr_detection_timeout]
    overlay_global.dup_host_ip_addr_detection_set(*default)
    assert_equal(default[0],
                 overlay_global.dup_host_ip_addr_detection_host_moves)
    assert_equal(default[1],
                 overlay_global.dup_host_ip_addr_detection_timeout)
    assert(Feature.nv_overlay_evpn_enabled?)

    # Set them to non-default values
    val = [200, 20]
    overlay_global.dup_host_ip_addr_detection_set(*val)
    assert_equal(val, overlay_global.dup_host_ip_addr_detection)
    assert_equal(val[0],
                 overlay_global.dup_host_ip_addr_detection_host_moves)
    assert_equal(val[1],
                 overlay_global.dup_host_ip_addr_detection_timeout)
  end

  def test_dup_host_mac_detection
    overlay_global = OverlayGlobal.new
    # These properties always exist, even without 'nv overlay evpn'
    default = [overlay_global.default_dup_host_mac_detection_host_moves,
               overlay_global.default_dup_host_mac_detection_timeout]
    assert_equal(default, overlay_global.dup_host_mac_detection)
    refute(Feature.nv_overlay_evpn_enabled?)

    # Set to a non-default value
    val = [160, 16]
    overlay_global.dup_host_mac_detection_set(*val)
    assert_equal(val, overlay_global.dup_host_mac_detection)
    refute(Feature.nv_overlay_evpn_enabled?)

    # Use the special defaulter method
    overlay_global.dup_host_mac_detection_default
    assert_equal(default, overlay_global.dup_host_mac_detection)
    refute(Feature.nv_overlay_evpn_enabled?)

    # Set explicitly to default too
    overlay_global.dup_host_mac_detection_set(*default)
    assert_equal(default, overlay_global.dup_host_mac_detection)
    refute(Feature.nv_overlay_evpn_enabled?)
  end

  def test_anycast_gateway_mac
    overlay_global = OverlayGlobal.new
    # Before enabling 'nv overlay evpn', this property does not exist
    assert_nil(overlay_global.anycast_gateway_mac)

    # Explicitly set to default and it should be enabled
    overlay_global.anycast_gateway_mac = \
      overlay_global.default_anycast_gateway_mac
    assert_equal(overlay_global.default_anycast_gateway_mac,
                 overlay_global.anycast_gateway_mac)
    assert(Feature.nv_overlay_evpn_enabled?)

    # Set to various non-default values
    %w(1.1.1 55.a10.ffff 1223.3445.5668).each do |mac|
      overlay_global.anycast_gateway_mac = mac
      assert_equal(Utils.zero_pad_macaddr(mac),
                   overlay_global.anycast_gateway_mac)
    end
  end
end
