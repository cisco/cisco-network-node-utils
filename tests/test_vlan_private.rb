# NXAPI New test for feature private-vlan
# Davide Celotto Febraury 2016
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
require_relative '../lib/cisco_node_utils/vlan'

include Cisco

# TestVlan - Minitest for Vlan node utility
class TestVlan < CiscoTestCase
  @skip_unless_supported = 'vlan'

  @@cleaned = false # rubocop:disable Style/ClassVars
  def cleanup
    Vlan.vlans.each do |vlan, obj|
      # skip reserved vlans
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      obj.destroy
    end
    config_no_warn('no feature vtp')
    config_no_warn('no feature private-vlan')
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
  end

  def test_private_type_default
    config_no_warn('no feature vtp')
    config_no_warn('feature private-vlan')
    v1 = Vlan.new(100)
    pv_type = ''
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
    else
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_association_default
    config_no_warn('no feature vtp')
    config_no_warn('feature private-vlan')
    v1 = Vlan.new(100)
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      return
    else
      result = []
      assert_equal(result, v1.private_vlan_association)
    end
  end

  def test_private_vlan_type_primary
    v1 = Vlan.new(100)
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_no_private_vlan_type_primary
    v1 = Vlan.new(200)
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = ''
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_multi_private_vlan_type_primary
    v1 = Vlan.new(100)
    v2 = Vlan.new(101)
    v3 = Vlan.new(200)
    v4 = Vlan.new(201)
    v5 = Vlan.new(203)
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
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
    end
  end

  def test_private_vlan_type_isolated
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_type_community
    v1 = Vlan.new(100)
    pv_type = 'community'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_type_isolated_primary
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      v2 = Vlan.new(200)
      pv_type = 'primary'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)
    end
  end

  def test_private_vlan_type_isolated_community_primary
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
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
    end
  end

  def test_private_vlan_type_change_isolated_to_primary
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'primary'
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_type_change_isolated_to_community
    v1 = Vlan.new(100)
    pv_type = 'isolated'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'community'
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_type_change_community_to_isolated
    v1 = Vlan.new(100)
    pv_type = 'community'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_type_change_community_to_primary
    v1 = Vlan.new(100)
    pv_type = 'community'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'primary'
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_type_change_primary_to_isolated
    v1 = Vlan.new(100)
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_type_change_primary_to_community
    v1 = Vlan.new(100)
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'community'
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
    end
  end

  def test_private_vlan_isolate_association
    vlan_list = %w(100 101)
    result = ['101']
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      v1.private_vlan_association = ['101']

      assert_equal(result, v1.private_vlan_association)
    end
  end

  def test_private_vlan_community_association
    vlan_list = %w(100 101)
    result = ['101']
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'community'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      v1.private_vlan_association = ['101']

      assert_equal(result, v1.private_vlan_association)
    end
  end

  def test_private_vlan_association_failure
    vlan_list = %w(100 101 200)
    result = %w(101 200)
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)
      pv_type = 'community'
      v3.private_vlan_type = pv_type
      assert_equal(pv_type, v3.private_vlan_type)

      v1.private_vlan_association = %w(101 200)

      assert_equal(result, v1.private_vlan_association)

      pv_type = 'isolated'
      assert_raises(RuntimeError, 'vlan misconf did not raise RuntimeError') do
        v3.private_vlan_type = pv_type
      end

      assert_equal(result, v1.private_vlan_association)

    end
  end

  def test_private_vlan_association_operational_and_not_operational
    vlan_list = %w(100 101 200)
    result = %w(101 200)

    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])

    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)

      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      v1.private_vlan_association = %w(101 200)

      assert_equal(result, v1.private_vlan_association)
    end
  end

  def test_private_vlan_association_vlan_not_configured
    vlan_list = %w(100 101 200)
    result = %w(101 200)
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      v1.private_vlan_association = %w(101 200)
      assert_equal(result, v1.private_vlan_association)
    end
  end

  def test_private_vlan_association_add_vlan
    vlan_list = %w(100 101)
    result = ['101']
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      v1.private_vlan_association = ['101']
      assert_equal(result, v1.private_vlan_association)
    end
  end

  def test_private_vlan_association_remove_vlan
    vlan_list = %w(100 101 200)
    result = %w(101 200)
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      pv_type = 'community'
      v3.private_vlan_type = pv_type
      assert_equal(pv_type, v3.private_vlan_type)

      v1.private_vlan_association = %w(101 200)
      assert_equal(result, v1.private_vlan_association)

      # v1.private_vlan_association_remove_vlans = '101'
      # result = '200'
      # assert_equal(result, vlan_list(v1))

    end
  end

  def test_no_private_vlan_association
    vlan_list = %w(100 101 200)
    result = %w(101 200)
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])

    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)

      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      pv_type = 'community'
      v3.private_vlan_type = pv_type
      assert_equal(pv_type, v3.private_vlan_type)

      v1.private_vlan_association = %w(101 200)
      assert_equal(result, v1.private_vlan_association)

      v1.private_vlan_association = ['200']
      result = ['200']
      assert_equal(result, v1.private_vlan_association)

    end
  end

  def test_no_private_vlan_association_all
    vlan_list = %w(100 101 200)
    result = %w(101 200)
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])

    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)

      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      pv_type = 'community'
      v3.private_vlan_type = pv_type
      assert_equal(pv_type, v3.private_vlan_type)

      v1.private_vlan_association = %w(101 200)
      assert_equal(result, v1.private_vlan_association)
      v1.private_vlan_association = []
      result = []
      assert_equal(result, v1.private_vlan_association)

    end
  end

  def test_private_vlan_isolate_community_association
    vlan_list = %w(100 101 200)
    result = %w(101 200)
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])
    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)
      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)
      pv_type = 'community'
      v3.private_vlan_type = pv_type
      assert_equal(pv_type, v3.private_vlan_type)

      v1.private_vlan_association = %w(101 200)

      assert_equal(result, v1.private_vlan_association)
    end
  end

  def test_private_vlan_multi_isolate_community_association
    vlan_list = %w(100 101 102 104 105 200 201 202)
    result = %w(101 104 105 200 202)
    v1 = Vlan.new(vlan_list[0])

    pv_type = 'primary'
    if validate_property_excluded?('vlan', 'private_vlan_type')
      assert_nil(v1.private_vlan_type)
      assert_raises(Cisco::UnsupportedError) do
        v1.private_vlan_type = pv_type
      end
      return
    else
      v2 = Vlan.new(vlan_list[1])
      v3 = Vlan.new(vlan_list[2])
      v4 = Vlan.new(vlan_list[3])
      v5 = Vlan.new(vlan_list[4])
      v6 = Vlan.new(vlan_list[5])
      v7 = Vlan.new(vlan_list[6])

      v1.private_vlan_type = pv_type
      assert_equal(pv_type, v1.private_vlan_type)

      pv_type = 'isolated'
      v2.private_vlan_type = pv_type
      assert_equal(pv_type, v2.private_vlan_type)

      pv_type = 'isolated'
      v3.private_vlan_type = pv_type
      assert_equal(pv_type, v3.private_vlan_type)

      pv_type = 'community'
      v4.private_vlan_type = pv_type
      assert_equal(pv_type, v4.private_vlan_type)

      pv_type = 'community'
      v5.private_vlan_type = pv_type
      assert_equal(pv_type, v5.private_vlan_type)

      pv_type = 'community'
      v6.private_vlan_type = pv_type
      assert_equal(pv_type, v6.private_vlan_type)

      pv_type = 'primary'
      v7.private_vlan_type = pv_type
      assert_equal(pv_type, v7.private_vlan_type)

      v1.private_vlan_association = ['101', '104-105', '200', '202']

      assert_equal(result, v1.private_vlan_association)

      v1.private_vlan_association = ['101', '103-105', '108']

      result = %w(101 103 104 105 108)
      assert_equal(result, v1.private_vlan_association)

      v1.private_vlan_association = ['101', '103-105', '108']
      result = %w(101 103 104 105 108)
      assert_equal(result, v1.private_vlan_association)
    end
  end
end
