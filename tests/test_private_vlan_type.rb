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
require_relative '../lib/cisco_node_utils/vlan'

include Cisco

# TestVlan - Minitest for Vlan node utility
class TestVlan < CiscoTestCase
  @@cleaned = false # rubocop:disable Style/ClassVars
  def cleanup
    Vlan.vlans.each do |vlan, obj|
      # skip reserved vlans
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      obj.destroy
    end
    config('no feature vtp')
    config('no feature private-vlan')
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
    config('no feature private-vlan')
  end

  def test_private_vlan_type_primary
    v1 = Vlan.new(100)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_no_private_vlan_type_primary
    v1 = Vlan.new(200)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = ''
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_multi_private_vlan_type_primary
    v1 = Vlan.new(100)
    v2 = Vlan.new(101)
    v3 = Vlan.new(200)
    v4 = Vlan.new(201)
    v5 = Vlan.new(203)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    v2.private_vlan_type = pv_type
    v3.private_vlan_type = pv_type
    v4.private_vlan_type = pv_type
    v5.private_vlan_type = pv_type

    assert_equal(pv_type, v1.private_vlan_type)
    assert_equal(pv_type, v2.private_vlan_type)
    assert_equal(pv_type, v3.private_vlan_type)
    assert_equal(pv_type, v4.private_vlan_type)
    assert_equal(pv_type, v5.private_vlan_type)
    v1.destroy
    v2.destroy
    v3.destroy
    v4.destroy
    v5.destroy
  end

  def test_private_vlan_type_unknown
    v1 = Vlan.new(400)
    pv_type = 'unknown'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_vtp
    v1 = Vlan.new(400)
    config('feature vtp')
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal('', v1.private_vlan_type)
    v1.destroy
    config('no feature vtp')
  end

  def test_private_vlan_type_isolated
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_type_community
    v1 = Vlan.new(100)
    pv_type = 'community'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_type_isolated_primary
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v2 = Vlan.new(200)
    pv_type = 'primary'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)
    v2.destroy
    v1.destroy
  end

  def test_private_vlan_type_isolated_community_primary
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v2 = Vlan.new(200)
    pv_type = 'primary'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)
    v3 = Vlan.new(300)
    pv_type = 'community'
    v3.private_vlan_type = pv_type
    assert_equal(pv_type, v3.private_vlan_type)
    v2.destroy
    v1.destroy
    v3.destroy
  end

  def test_private_vlan_type_change_isolated_to_primary
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_type_change_isolated_to_community
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'community'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_type_change_community_to_isolated
    v1 = Vlan.new(100)
    pv_type = 'community'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_type_change_community_to_primary
    v1 = Vlan.new(100)
    pv_type = 'community'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_type_change_primary_to_isolated
    v1 = Vlan.new(100)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end

  def test_private_vlan_type_change_primary_to_community
    v1 = Vlan.new(100)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'community'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    v1.destroy
  end
end
