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
    skip('Only supported on N7K,N9K') unless node.product_id[/N[7|9]K/]
    no_vni
  end

  def teardown
    no_vni
    super
  end

  def no_vni
    config('no feature vni') if node.product_id[/N7K/]
    config('no feature vn-segment-vlan-based') if node.product_id[/N9K/]
  end

  def test_vni_create_destroy
    skip('Only supported on N7K') unless node.product_id[/N7K/]
    v1 = Vni.new(10_001)
    v2 = Vni.new(10_002)
    v3 = Vni.new(10_003)
    assert_equal(3, Vni.vnis.keys.count)

    v2.destroy
    assert_equal(2, Vni.vnis.keys.count)

    v1.destroy
    v3.destroy
    assert_equal(0, Vni.vnis.keys.count)
  end

  def test_mapped_vlan
    skip('Only supported on N9K') unless node.product_id[/N9K/]
    # Set the vni vlan mapping
    vni = Vni.new(10_000)
    vni.mapped_vlan = 100
    assert_equal(100, vni.mapped_vlan,
                 'Error: mapped-vlan mismatch')
    # Now clear the vni vlan mapping
    vni.mapped_vlan = vni.default_mapped_vlan
    assert_nil(vni.mapped_vlan, 'Error: cannot clear vni vlan mapping')
  end

  def test_multiple_vnis_vlans
    skip('Only supported on N9K') unless node.product_id[/N9K/]
    # Set vni to vlan mappings
    vni_to_vlan_map = { 10_000 => 100, 20_000 => 200, 30_000 => 300 }
    vni_to_vlan_map.each do |vni, vlan|
      vni_id = Vni.new(vni)
      vni_id.mapped_vlan = vlan
      assert_equal(vlan, vni_id.mapped_vlan,
                   'Error: mapped-vlan mismatch')
    end
    # Clear all mappings
    vni_to_vlan_map.each do |vni, _vlan|
      vni_id = Vni.new(vni)
      vni_id.mapped_vlan = vni_id.default_mapped_vlan
      assert_nil(vni_id.mapped_vlan, 'Error: cannot clear vni vlan mapping')
    end
  end

  def test_shutdown
    skip('Only supported on N7K') unless node.product_id[/N7K/]
    vni = Vni.new(10_000)
    vni.shutdown = true
    assert(vni.shutdown)

    vni.shutdown = false
    refute(vni.shutdown)

    vni.shutdown = !vni.default_shutdown
    assert_equal(!vni.default_shutdown, vni.shutdown)

    vni.shutdown = vni.default_shutdown
    assert_equal(vni.default_shutdown, vni.shutdown)
  end
end
