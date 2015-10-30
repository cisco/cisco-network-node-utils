# Copyright (c) 2013-2015 Cisco and/or its affiliates.
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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/vxlan_global', __FILE__)

include Cisco

# TestVxlanGlobal - Minitest for VxlanGlobal node utility
class TestVxlanGlobal < CiscoTestCase
  def setup
    super
    no_feature_vxlan_global
  end

  def teardown
    no_feature_vxlan_global
    super
  end

  def no_feature_vxlan_global
    config('no feature fabric forwarding')
  end

  def test_feature_on_off
    feat = VxlanGlobal.new
    feat.feature_enable
    assert(VxlanGlobal.feature_enabled)

    feat.feature_disable
    refute(VxlanGlobal.feature_enabled)
  end

  def test_dup_host_ip_addr_detection_set
    vxlan_global = VxlanGlobal.new
    val = [200, 20]
    vxlan_global.feature_enable
    vxlan_global.dup_host_ip_addr_detection_set(' ', val[0], val[1])
    assert_equal(val, vxlan_global.dup_host_ip_addr_detection,
                 'Error: fabric forwarding dup_host_ip_addr_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_ip_addr_detection_clear
    vxlan_global = VxlanGlobal.new
    val = [200, 20]
    # After the config is cleared, the get method should return
    # the default values
    default = [5, 180]
    vxlan_global.feature_enable
    vxlan_global.dup_host_ip_addr_detection_set('no', val[0], val[1])
    assert_equal(default, vxlan_global.dup_host_ip_addr_detection,
                 'Error: fabric forwarding dup_host_ip_addr_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_mac_detection_set
    vxlan_global = VxlanGlobal.new
    val = [200, 20]
    vxlan_global.dup_host_mac_detection_set(val[0], val[1])
    assert_equal(val, vxlan_global.dup_host_mac_detection,
                 'Error: l2rib dup_host_mac_detection ' \
                 'get values mismatch')
  end

  def test_dup_host_mac_detection_default
    vxlan_global = VxlanGlobal.new
    # After the config is cleared, the get method should return
    # the default values
    default = [5, 180]
    vxlan_global.dup_host_mac_detection_default
    assert_equal(default, vxlan_global.dup_host_mac_detection,
                 'Error: l2rib dup_host_mac_detection ' \
                 'get values mismatch')
  end

  def test_anycast_gateway_mac_set
    vxlan_global = VxlanGlobal.new
    mac_addr = '1223.3445.5668'
    vxlan_global.feature_enable
    vxlan_global.anycast_gateway_mac_set(' ', mac_addr)
    assert_equal(mac_addr, vxlan_global.anycast_gateway_mac,
                 'Error: anycast-gateway-mac mismatch')
  end

  def test_anycast_gateway_mac_clear
    vxlan_global = VxlanGlobal.new
    vxlan_global.feature_enable
    vxlan_global.anycast_gateway_mac_set('no', '')
    assert_equal(' ', vxlan_global.anycast_gateway_mac,
                 'Error: anycast-gateway-mac mismatch')
  end
end
