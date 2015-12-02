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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/vni'

include Cisco

# TestVni - Minitest for Vni node utility
class TestVni < CiscoTestCase
  def setup
    super
    no_vni
  end

  def teardown
    no_vni
    super
  end

  def no_vni
    config('no feature vn-segment-vlan-based')
  end

  def test_on_off
    vni = Vni.new(1_000_0, true)
    assert_equal(:enabled, vni.feature, 'Error: vni feature not enabled')

    vni.feature_set(:disabled)
    assert_equal(:disabled, vni.feature, 'Error: vni feature still enabled')
  end

  def test_mapped_vlan
    # Set the vni vlan mapping
    vni = Vni.new(1_000_0)
    vni.mapped_vlan = 100
    assert_equal(100, vni.mapped_vlan,
                 'Error: mapped-vlan mismatch')
    # Now clear the vni vlan mapping
    vni.mapped_vlan = vni.default_vlan
    assert_equal(nil, vni.mapped_vlan,
                 'Error: cannot clear vni vlan mapping')
  end

  def test_multiple_vnis_vlans
    # Set vni to vlan mappings
    vni_to_vlan_map = { 1_000_0 => 100, 2_000_0 => 200, 3_000_0 => 300 }
    vni_to_vlan_map.each do |vni, vlan|
      vni_id = Vni.new(vni)
      vni_id.mapped_vlan = vlan
      assert_equal(vlan, vni_id.mapped_vlan,
                   'Error: mapped-vlan mismatch')
    end
    # Clear all mappings
    vni_to_vlan_map.each do |vni, _vlan|
      vni_id = Vni.new(vni)
      vni_id.mapped_vlan = vni_id.default_vlan
      assert_equal(nil, vni_id.mapped_vlan,
                   'Error: cannot clear vni vlan mapping')
    end
  end
end
