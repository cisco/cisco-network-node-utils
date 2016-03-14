# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/bridge_domain'
require_relative '../lib/cisco_node_utils/vlan'

include Cisco

# TestBridgeDomain - Minitest for bridge domain class.
class TestBridgeDomain < CiscoTestCase
  @skip_unless_supported = 'bridge_domain'
  @@cleaned = false # rubocop:disable Style/ClassVars

  def cleanup
    BridgeDomain.bds.each do |_bd, obj|
      obj.destroy
    end
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    super
    cleanup
  end

  def test_single_bd_create_destroy
    bd = BridgeDomain.new('100', true)
    bds = BridgeDomain.bds
    assert(bds.key?('100'), 'Error: failed to create bridge-domain 100')

    bd.destroy
    bds = BridgeDomain.bds
    refute(bds.key?('100'), 'Error: failed to destroy bridge-domain 100')
  end

  def test_bd_create_if_vlan_exists
    vlan = Vlan.new(100)
    assert_raises(RuntimeError,
                  'Vlan already exist did not raise RuntimeError') do
      BridgeDomain.new(100)
    end
    vlan.destroy
  end

  def test_create_already_existing_bd
    create = '100-120'
    BridgeDomain.new('100-110,115')
    bd = BridgeDomain.new('100-120')
    bds = BridgeDomain.bds
    BridgeDomain.bd_ids_to_array(create).each do |id|
      assert(bds.key?(id.to_s), 'Error: failed to create bridge-domain ' << id)
    end
    bd.destroy
  end

  def test_multiple_bd_create_destroy
    create = '101-102,120'
    bdlist = BridgeDomain.bd_ids_to_array(create)

    bd = BridgeDomain.new(create, true)
    bds = BridgeDomain.bds
    bdlist.each do |id|
      assert(bds.key?(id.to_s), 'Error: failed to create bridge-domain ' << id)
    end

    bd.destroy
    bds = BridgeDomain.bds
    bdlist.each do |id|
      refute(bds.key?(id.to_s), 'Error: failed to destroy bridge-domain ' << id)
    end
  end

  def test_bd_create_noorder_and_space
    create = '100, 90, 200, 2-4'
    bd = BridgeDomain.new(create)
    bds = BridgeDomain.bds
    BridgeDomain.bd_ids_to_array(create).each do |id|
      assert(bds.key?(id.to_s), 'Error: failed to create bridge-domain ' << id)
    end
    bd.destroy
  end

  def test_bd_shutdown
    bd = BridgeDomain.new(101)
    refute(bd.shutdown)
    bd.shutdown = true
    assert(bd.shutdown)
    bd.destroy
  end

  def test_bd_name
    bd = BridgeDomain.new(101)
    assert_equal(bd.default_bd_name, bd.bd_name,
                 'Error: Bridge-Domain name not initialized to default')

    name = 'Pepsi'
    bd.bd_name = name
    assert_equal(name, bd.bd_name,
                 'Error: Bridge-Domain name not updated to #{name}')

    bd.bd_name = bd.default_bd_name
    assert_equal(bd.default_bd_name, bd.bd_name,
                 'Error: Bridge-Domain name not restored to default')
    bd.destroy
  end

  def test_bd_fabric_control
    bd = BridgeDomain.new('100')
    assert_equal(bd.default_fabric_control, bd.fabric_control,
                 'Error: Bridge-Domain fabric-control is not matching')
    bd.fabric_control = true
    assert(bd.fabric_control)
    bd.destroy
  end

  def test_bd_member_vni
    mt_full_interface?
    bd = BridgeDomain.new(100)
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(bd.default_member_vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = '5000'
    bd.member_vni = vni
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.member_vni = ''
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(bd.default_member_vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.destroy
  end

  def test_mapped_bd_member_vni
    mt_full_interface?
    bd = BridgeDomain.new(100)
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(bd.default_member_vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = '5000'
    bd.member_vni = vni
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')
    vni = '6000'
    assert_raises(RuntimeError,
                  'Should raise RuntimeError as BD already mapped to vni ') do
      bd.member_vni = vni
    end
    bd.destroy
  end

  def test_multiple_bd_vni_mapping
    mt_full_interface?
    bd = BridgeDomain.new('100,110,120')
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(bd.default_member_vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = '5000,5010,5020'
    bd.member_vni = vni
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = ''
    bd.member_vni = vni
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')
    bd.destroy
  end

  def test_member_vni_empty_assign
    mt_full_interface?
    bd = BridgeDomain.new(100)
    bd.member_vni = ''
    curr_vni = bd.member_vni.values.join(',')
    assert_equal(bd.default_member_vni, curr_vni,
                 'Error: Bridge-Domain is mapped to different vnis')
    bd.destroy
  end

  def test_another_bd_as_fabric_control
    bd = BridgeDomain.new(100)
    assert_equal(bd.default_fabric_control, bd.fabric_control,
                 'Error: Bridge-Domain fabric-control is not matching')
    bd.fabric_control = true
    assert(bd.fabric_control)
    another_bd = BridgeDomain.new(101)

    assert_raises(RuntimeError,
                  'BD misconfig did not raise RuntimeError') do
      another_bd.fabric_control = true
    end
    bd.destroy
    another_bd.destroy
  end

  def test_invalid_bd_create
    assert_raises(RuntimeError,
                  'BD misconfig did not raise RuntimeError') do
      BridgeDomain.new('90, 5000-5004,100')
    end
  end
end
