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
    skip('Only supported on N3K,N7K,N9K') unless node.product_id[/N[379]K/]
    no_vni
  end

  def teardown
    no_vni
    super
  end

  def no_vni
    config('no feature vni') if node.product_id[/N7K/]
    config('no feature vn-segment-vlan-based') if node.product_id[/N(3|9)K/]
  end

  def test_mt_full_vni_create_destroy
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

  # def test_mt_full_encapsulation_dot1q
  # TBD
  # end

  # def test_mt_full_mapped_bd
  # TBD
  # end

  def test_mt_full_shutdown
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

  def test_mt_lite_mapped_vlan
    skip('Only supported on N3K,N9K') unless node.product_id[/N[39]K/]
    # Set the vni vlan mapping
    v = Vni.new(10_000)
    v.mapped_vlan = 100
    assert_equal(100, v.mapped_vlan,
                 'Error: mapped-vlan mismatch')
    # Now clear the vni vlan mapping
    v.mapped_vlan = v.default_mapped_vlan
    assert_nil(v.mapped_vlan, 'Error: cannot clear vni vlan mapping')
    v.destroy

    # Multiples: Set vni to vlan mappings
    vni_to_vlan_map = { 10_000 => 100, 20_000 => 200, 30_000 => 300 }
    vni_to_vlan_map.each do |vni, vlan|
      v = Vni.new(vni)
      v.mapped_vlan = vlan
      assert_equal(vlan, v.mapped_vlan, 'Error: mapped-vlan mismatch')
    end
    # Clear all mappings
    vni_to_vlan_map.each do |vni, _|
      v = Vni.new(vni)
      v.mapped_vlan = v.default_mapped_vlan
      assert_nil(v.mapped_vlan, 'Error: cannot clear vni vlan mapping')
    end
  end
end
