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
require_relative '../lib/cisco_node_utils/vxlan_global'

include Cisco

# TestVxlanGlobal - Minitest for VxlanGlobal node utility
class TestVxlanGlobal < CiscoTestCase
  @@clean = false # rubocop:disable Style/ClassVars
  def setup
    super
    no_vxlan_global unless @@clean
    @@clean = true # rubocop:disable Style/ClassVars
  end

  def no_vxlan_global
    config('no feature fabric forwarding')
    config('no nv overlay evpn')
  end

  def test_dup_host_ip_addr_detection_set
    vxlan_global = VxlanGlobal.new
    val = [200, 20]
    vxlan_global.dup_host_ip_addr_detection_set(val[0], val[1])
    assert_equal(val, vxlan_global.dup_host_ip_addr_detection,
                 'Error: fabric forwarding dup_host_ip_addr_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_ip_addr_detection_clear
    vxlan_global = VxlanGlobal.new
    val = [5, 180]
    # After the config is cleared, the get method should return
    # the default values
    default = [vxlan_global.default_dup_host_ip_addr_detection_host_moves,
               vxlan_global.default_dup_host_ip_addr_detection_timeout]
    vxlan_global.dup_host_ip_addr_detection_set(val[0], val[1])
    assert_equal(default, vxlan_global.dup_host_ip_addr_detection,
                 'Error: fabric forwarding dup_host_ip_addr_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_mac_detection_set
    vxlan_global = VxlanGlobal.new
    val = [160, 16]
    vxlan_global.dup_host_mac_detection_set(val[0], val[1])
    assert_equal(val, vxlan_global.dup_host_mac_detection,
                 'Error: l2rib dup_host_mac_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_mac_detection_default
    vxlan_global = VxlanGlobal.new
    # After the config is cleared, the get method should return
    # the default values
    default = [vxlan_global.default_dup_host_mac_detection_host_moves,
               vxlan_global.default_dup_host_mac_detection_timeout]
    vxlan_global.dup_host_mac_detection_default
    assert_equal(default, vxlan_global.dup_host_mac_detection,
                 'Error: l2rib dup_host_mac_detection ' \
                 'get values mismatch')
  end

  def test_anycast_gateway_mac_set
    vxlan_global = VxlanGlobal.new
    mac_addr = '1223.3445.5668'
    vxlan_global.anycast_gateway_mac = mac_addr
    assert_equal(mac_addr, vxlan_global.anycast_gateway_mac,
                 'Error: anycast-gateway-mac mismatch')
  end

  def test_anycast_gateway_mac_clear
    vxlan_global = VxlanGlobal.new
    vxlan_global.anycast_gateway_mac = vxlan_global.default_anycast_gateway_mac
    assert_equal(vxlan_global.default_anycast_gateway_mac,
                 vxlan_global.anycast_gateway_mac,
                 'Error: anycast-gateway-mac mismatch')
  end
end
