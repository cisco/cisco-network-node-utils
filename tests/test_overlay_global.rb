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
require_relative '../lib/cisco_node_utils/feature'
require_relative '../lib/cisco_node_utils/overlay_global'

include Cisco

# TestOverlayGlobal - Minitest for OverlayGlobal node utility
class TestOverlayGlobal < CiscoTestCase
  @@clean = false # rubocop:disable Style/ClassVars
  def setup
    super
    no_overlay_global unless @@clean
    @@clean = true # rubocop:disable Style/ClassVars
  end

  def no_overlay_global
    config('no feature fabric forwarding')
    config('no nv overlay evpn')
  end

  def test_dup_host_ip_addr_detection_set
    overlay_global = OverlayGlobal.new
    val = [200, 20]
    overlay_global.dup_host_ip_addr_detection_set(val[0], val[1])
    assert_equal(val, overlay_global.dup_host_ip_addr_detection,
                 'Error: fabric forwarding dup_host_ip_addr_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_ip_addr_detection_clear
    overlay_global = OverlayGlobal.new
    val = [5, 180]
    # After the config is cleared, the get method should return
    # the default values
    default = [overlay_global.default_dup_host_ip_addr_detection_host_moves,
               overlay_global.default_dup_host_ip_addr_detection_timeout]
    overlay_global.dup_host_ip_addr_detection_set(val[0], val[1])
    assert_equal(default, overlay_global.dup_host_ip_addr_detection,
                 'Error: fabric forwarding dup_host_ip_addr_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_mac_detection_set
    overlay_global = OverlayGlobal.new
    val = [160, 16]
    overlay_global.dup_host_mac_detection_set(val[0], val[1])
    assert_equal(val, overlay_global.dup_host_mac_detection,
                 'Error: l2rib dup_host_mac_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_mac_detection_default
    overlay_global = OverlayGlobal.new
    # After the config is cleared, the get method should return
    # the default values
    default = [overlay_global.default_dup_host_mac_detection_host_moves,
               overlay_global.default_dup_host_mac_detection_timeout]
    overlay_global.dup_host_mac_detection_default
    assert_equal(default, overlay_global.dup_host_mac_detection,
                 'Error: l2rib dup_host_mac_detection ' \
                 'get values mismatch')
  end

  def test_anycast_gateway_mac_set
    overlay_global = OverlayGlobal.new
    mac_addr = '1223.3445.5668'
    overlay_global.anycast_gateway_mac = mac_addr
    assert_equal(mac_addr, overlay_global.anycast_gateway_mac,
                 'Error: anycast-gateway-mac mismatch')
  end

  def test_anycast_gateway_mac_clear
    overlay_global = OverlayGlobal.new
    overlay_global.anycast_gateway_mac = \
      overlay_global.default_anycast_gateway_mac
    assert_equal(overlay_global.default_anycast_gateway_mac,
                 overlay_global.anycast_gateway_mac,
                 'Error: anycast-gateway-mac mismatch')
  end
end
