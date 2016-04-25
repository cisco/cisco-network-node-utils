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
    remove_all_vlans
    remove_all_bridge_domains
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
    super
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
    assert_raises(CliError,
                  'Vlan already exist did not raise CliError') do
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

    name = 'my_bridge'
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

  def test_another_bd_as_fabric_control
    bd = BridgeDomain.new(100)
    assert_equal(bd.default_fabric_control, bd.fabric_control,
                 'Error: Bridge-Domain fabric-control is not matching')
    bd.fabric_control = true
    assert(bd.fabric_control)
    another_bd = BridgeDomain.new(101)

    assert_raises(CliError,
                  'BD misconfig did not raise CliError') do
      another_bd.fabric_control = true
    end
    bd.destroy
    another_bd.destroy
  end

  def test_invalid_bd_create
    assert_raises(CliError,
                  'BD misconfig did not raise CliError') do
      BridgeDomain.new('90, 5000-5004,100')
    end
  end

  def test_multiple_bd_combinations
    bds = BridgeDomain.new('100-110')
    bd_hash = {}
    bd_hash['100'] = [true, false, 'bd100']
    bd_hash['105'] = [true, true, 'bd105']
    bd_hash['107'] = [true, false, 'bd107']
    bd_hash['110'] = [true, false, '']
    BridgeDomain.bds.each do |bd, obj|
      if bd_hash.key?(bd)
        obj.shutdown = bd_hash[bd][0]
        assert_equal(bd_hash[bd][0], obj.shutdown,
                     'Error: Bridge-Domain state is not matching')

        obj.fabric_control = bd_hash[bd][1]
        assert_equal(bd_hash[bd][1], obj.fabric_control,
                     'Error: Bridge-Domain type is not matching')

        if bd_hash[bd][2] != ''
          obj.bd_name = bd_hash[bd][2]
          assert_equal(bd_hash[bd][2], obj.bd_name,
                       'Error: Bridge-Domain name is not matching')
        else
          assert_equal(obj.default_bd_name, obj.bd_name,
                       'Error: Bridge-Domain name is not matching')
        end
      else
        assert_equal(obj.default_shutdown, obj.shutdown,
                     'Error: Bridge-Domain state is not matching')
        assert_equal(obj.default_fabric_control, obj.fabric_control,
                     'Error: Bridge-Domain type is not matching')
        assert_equal(obj.default_bd_name, obj.bd_name,
                     'Error: Bridge-Domain name is not matching')
      end
    end
    bds.destroy
  end
end
