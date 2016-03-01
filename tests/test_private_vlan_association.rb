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
    Vlan.vlans.each do |vlan, _obj|
      # skip reserved vlans
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      # obj.destroy
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
    config('no feature vtp')
  end

  def test_private_vlan_isolate_association
    vlan_list = %w(100 101)
    result = { '101' => 'isolated' }
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = vlan_list[1]
    v1.private_vlan_association = config

    assert_equal(result, v1.private_vlan_association)
    v1.destroy
    v2.destroy
  end

  def test_private_vlan_community_association
    vlan_list = %w(100 101)
    result = { '101' => 'community' }
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'community'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = vlan_list[1]
    v1.private_vlan_association = config

    assert_equal(result, v1.private_vlan_association)
    v1.destroy
    v2.destroy
  end

  def test_private_vlan_association_failure
    vlan_list = %w(100 101 200)
    result = { '101' => 'isolated', '200' => 'community' }
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)
    pv_type = 'community'
    v3.private_vlan_type = pv_type
    assert_equal(pv_type, v3.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = '101,200'
    v1.private_vlan_association = config

    assert_equal(result, v1.private_vlan_association)

    pv_type = 'isolated'
    assert_raises(RuntimeError, 'vlan misconfig did not raise RuntimeError') do
      v2.private_vlan_type = pv_type
    end

    assert_equal(result, v1.private_vlan_association)

    v1.destroy
    v2.destroy
    v3.destroy
  end

  def test_private_vlan_association_operational_and_not_operational
    vlan_list = %w(100 101 200)
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])

    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)

    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = '101,200'
    v1.private_vlan_association = config

    v1.destroy
    v2.destroy
    v3.destroy
  end

  def test_private_vlan_association_vlan_not_configured
    vlan_list = %w(100 101 200)
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = '101,200'
    v1.private_vlan_association = config

    v1.destroy
    v2.destroy
  end

  def test_private_vlan_association_add_vlan
    vlan_list = %w(100 101)
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    config[:oper] = 'add'
    config[:vlan_list] = '101'
    v1.private_vlan_association = config

    v1.destroy
    v2.destroy
  end

  def test_private_vlan_association_remove_vlan
    vlan_list = %w(100 101 200)
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    pv_type = 'community'
    v3.private_vlan_type = pv_type
    assert_equal(pv_type, v3.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = '101,200'
    v1.private_vlan_association = config

    config[:oper] = 'rem'
    config[:vlan_list] = '101'
    v1.private_vlan_association = config

    v1.destroy
    v2.destroy
    v3.destroy
  end

  def test_no_private_vlan_association
    vlan_list = %w(100 101 200)
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])

    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)

    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    pv_type = 'community'
    v3.private_vlan_type = pv_type
    assert_equal(pv_type, v3.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = '101,200'
    v1.private_vlan_association = config

    config[:oper] = 'default'
    config[:vlan_list] = '101'
    v1.private_vlan_association = config

    v1.destroy
    v2.destroy
    v3.destroy
  end

  def test_no_private_vlan_association_all
    vlan_list = %w(100 101 200)
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])

    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)

    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)

    pv_type = 'community'
    v3.private_vlan_type = pv_type
    assert_equal(pv_type, v3.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = '101,200'
    v1.private_vlan_association = config

    config[:oper] = 'default'
    config[:vlan_list] = ''
    v1.private_vlan_association = config

    v1.destroy
    v2.destroy
    v3.destroy
  end

  def test_private_vlan_isolate_community_association
    vlan_list = %w(100 101 200)
    result = { '101' => 'isolated', '200' => 'community' }
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
    pv_type = 'isolated'
    v2.private_vlan_type = pv_type
    assert_equal(pv_type, v2.private_vlan_type)
    pv_type = 'community'
    v3.private_vlan_type = pv_type
    assert_equal(pv_type, v3.private_vlan_type)

    config[:oper] = ''
    config[:vlan_list] = '101,200'
    v1.private_vlan_association = config

    assert_equal(result, v1.private_vlan_association)
    v1.destroy
    v2.destroy
    v3.destroy
  end

  def test_private_vlan_multi_isolate_community_association
    vlan_list = %w(100 101 102 104 105 200 201 202)
    result = { '101' => 'isolated',
               '104' => 'community',
               '105' => 'community',
               '200' => 'community',
               '202' => 'non-operational',
    }
    config = {}
    v1 = Vlan.new(vlan_list[0])
    v2 = Vlan.new(vlan_list[1])
    v3 = Vlan.new(vlan_list[2])
    v4 = Vlan.new(vlan_list[3])
    v5 = Vlan.new(vlan_list[4])
    v6 = Vlan.new(vlan_list[5])
    v7 = Vlan.new(vlan_list[6])
    v8 = Vlan.new(vlan_list[7])

    pv_type = 'primary'
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

    config[:oper] = ''
    config[:vlan_list] = '101,104-105,200,202'
    v1.private_vlan_association = config

    assert_equal(result, v1.private_vlan_association)
    v1.destroy
    v2.destroy
    v3.destroy
    v4.destroy
    v5.destroy
    v6.destroy
    v7.destroy
    v8.destroy
  end
end
