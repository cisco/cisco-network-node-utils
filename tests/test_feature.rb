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
require_relative '../lib/cisco_node_utils/feature'

include Cisco

# TestVrf - Minitest for Vrf node utility class
class TestFeature < CiscoTestCase
  def setup
    super
    @default_show_command = 'show run | i feature'
  end

  # feature test helper
  def feature(f)
    config("no feature #{f}") if Feature.send("#{f}_enabled?")
    refute_show_match(pattern: /^feature #{f}$/,
                      msg:     "Feature #{f} should not be enabled")

    Feature.send("#{f}_enable")
    # Some features (BGP on n5k!) are slow starters...
    unless Feature.send("#{f}_enabled?")
      sleep 1
      node.cache_flush
    end
    assert(Feature.send("#{f}_enabled?"),
           "Feature #{f} is not enabled")

    # Cleanup
    config("no feature #{f}")
  end

  # -------------------------

  def test_bgp
    feature('bgp')
  end

  def test_fabric
    feature('fabric')
  end

  def test_fabric_forwarding
    skip('This feature is only supported on 7.0(3)I2 images') unless
      node.os_version[/7.0\(3\)I2\(/]
    feature('fabric_forwarding')
  end

  def test_nv_overlay
    feature('nv_overlay')
  end

  def test_nv_overlay_evpn
    feature('nv_overlay_evpn')
  end

  def test_vn_segment_vlan_based
    feature('vn_segment_vlan_based')
  rescue RuntimeError => e
    hardware_supports_feature?(e.message)
  end
end
