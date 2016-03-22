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
require_relative '../lib/cisco_node_utils/stp_global'

# TestStpGlobal - Minitest for StpGlobal node utility class
class TestStpGlobal < CiscoTestCase
  @skip_unless_supported = 'stp_global'
  # TESTS

  @@clean = false # rubocop:disable Style/ClassVars
  def setup
    super
    config 'no spanning-tree mode'
    config 'system bridge-domain none' if /N7/ =~ node.product_id
    @intf = Interface.new(interfaces[0])

    # Only pre-clean interface on initial setup
    config("default interface #{interfaces[0]}") unless @@clean
    @@clean = true # rubocop:disable Style/ClassVars
    @intf.switchport_enable
  end

  def teardown
    config 'no spanning-tree mode'
    config 'system bridge-domain none' if /N7/ =~ node.product_id
    super
  end

  def test_bd_forward_time_change
    global = StpGlobal.new('default')
    bdft = [%w(2-4,6,8-12 4), %w(14 30)]
    if validate_property_excluded?('stp_global', 'bd_forward_time')
      assert_nil(global.bd_forward_time)
      assert_raises(Cisco::UnsupportedError) do
        global.bd_forward_time = bdft
      end
    else
      config 'system bridge-domain all'
      global.bd_forward_time = global.default_bd_forward_time
      assert_equal(global.default_bd_forward_time,
                   global.bd_forward_time)
      global.bd_forward_time = bdft
      assert_equal(bdft, global.bd_forward_time)
      global.bd_forward_time = global.default_bd_forward_time
      assert_equal(global.default_bd_forward_time,
                   global.bd_forward_time)
    end
  end

  def test_bd_hello_time_change
    global = StpGlobal.new('default')
    bdft = [%w(2-4,6,8-12 1), %w(14 10)]
    if validate_property_excluded?('stp_global', 'bd_hello_time')
      assert_nil(global.bd_hello_time)
      assert_raises(Cisco::UnsupportedError) do
        global.bd_hello_time = bdft
      end
    else
      config 'system bridge-domain all'
      global.bd_hello_time = global.default_bd_hello_time
      assert_equal(global.default_bd_hello_time,
                   global.bd_hello_time)
      global.bd_hello_time = bdft
      assert_equal(bdft, global.bd_hello_time)
      global.bd_hello_time = global.default_bd_hello_time
      assert_equal(global.default_bd_hello_time,
                   global.bd_hello_time)
    end
  end

  def test_bd_max_age_change
    global = StpGlobal.new('default')
    bdft = [%w(2-4,6,8-12 10), %w(14 40)]
    if validate_property_excluded?('stp_global', 'bd_max_age')
      assert_nil(global.bd_max_age)
      assert_raises(Cisco::UnsupportedError) do
        global.bd_max_age = bdft
      end
    else
      config 'system bridge-domain all'
      global.bd_max_age = global.default_bd_max_age
      assert_equal(global.default_bd_max_age,
                   global.bd_max_age)
      global.bd_max_age = bdft
      assert_equal(bdft, global.bd_max_age)
      global.bd_max_age = global.default_bd_max_age
      assert_equal(global.default_bd_max_age,
                   global.bd_max_age)
    end
  end

  def test_bd_priorities_change
    global = StpGlobal.new('default')
    bdft = [%w(2-4,6,8-12 4096), %w(14 8192)]
    if validate_property_excluded?('stp_global', 'bd_priority')
      assert_nil(global.bd_priority)
      assert_nil(global.bd_root_priority)
      assert_nil(global.bd_designated_priority)
      assert_raises(Cisco::UnsupportedError) do
        global.bd_priority = bdft
      end
      assert_raises(Cisco::UnsupportedError) do
        global.bd_root_priority = bdft
      end
      assert_raises(Cisco::UnsupportedError) do
        global.bd_designated_priority = bdft
      end
    else
      config 'system bridge-domain all'
      global.bd_priority = global.default_bd_priority
      global.bd_root_priority = global.default_bd_root_priority
      global.bd_designated_priority = global.default_bd_designated_priority
      assert_equal(global.default_bd_priority,
                   global.bd_priority)
      assert_equal(global.default_bd_root_priority,
                   global.bd_root_priority)
      assert_equal(global.default_bd_designated_priority,
                   global.bd_designated_priority)
      global.bd_priority = bdft
      global.bd_root_priority = bdft
      global.bd_designated_priority = bdft
      assert_equal(bdft, global.bd_priority)
      assert_equal(bdft, global.bd_root_priority)
      assert_equal(bdft, global.bd_designated_priority)
      global.bd_priority = global.default_bd_priority
      global.bd_root_priority = global.default_bd_root_priority
      global.bd_designated_priority = global.default_bd_designated_priority
      assert_equal(global.default_bd_priority,
                   global.bd_priority)
      assert_equal(global.default_bd_root_priority,
                   global.bd_root_priority)
      assert_equal(global.default_bd_designated_priority,
                   global.bd_designated_priority)
    end
  end

  def test_get_set_bpdufilter
    global = StpGlobal.new('default')
    global.bpdufilter = true
    assert_equal(true, global.bpdufilter)
    global.bpdufilter =
      global.default_bpdufilter
    assert_equal(global.default_bpdufilter,
                 global.bpdufilter)
  end

  def test_get_set_bpduguard
    global = StpGlobal.new('default')
    global.bpduguard = true
    assert_equal(true, global.bpduguard)
    global.bpduguard =
      global.default_bpduguard
    assert_equal(global.default_bpduguard,
                 global.bpduguard)
  end

  def test_get_set_bridge_assurance
    global = StpGlobal.new('default')
    global.bridge_assurance = false
    assert_equal(false, global.bridge_assurance)
    global.bridge_assurance =
      global.default_bridge_assurance
    assert_equal(global.default_bridge_assurance,
                 global.bridge_assurance)
  end

  def test_get_set_domain
    global = StpGlobal.new('default')
    if validate_property_excluded?('stp_global', 'domain')
      assert_nil(global.domain)
      assert_raises(Cisco::UnsupportedError) do
        global.domain = 200
      end
    else
      global.domain = 100
      assert_equal(100, global.domain)
      global.domain =
        global.default_domain
      assert_equal(global.default_domain,
                   global.domain)
    end
  end

  def test_get_set_fcoe
    global = StpGlobal.new('default')
    if validate_property_excluded?('stp_global', 'fcoe')
      assert_nil(global.fcoe)
      assert_raises(Cisco::UnsupportedError) do
        global.fcoe = false
      end
    else
      global.fcoe = false
      assert_equal(false, global.fcoe)
      global.fcoe =
        global.default_fcoe
      assert_equal(global.default_fcoe,
                   global.fcoe)
    end
  end

  def test_get_set_loopguard
    global = StpGlobal.new('default')
    global.loopguard = true
    assert_equal(true, global.loopguard)
    global.loopguard =
      global.default_loopguard
    assert_equal(global.default_loopguard,
                 global.loopguard)
  end

  def test_get_set_mode
    global = StpGlobal.new('default')
    global.mode = 'mst'
    assert_equal('mst', global.mode)
    global.mode =
      global.default_mode
    assert_equal(global.default_mode,
                 global.mode)
  end

  def test_get_set_mst_priorities
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_priority = global.default_mst_priority
    global.mst_root_priority = global.default_mst_root_priority
    global.mst_designated_priority = global.default_mst_designated_priority
    assert_equal(global.default_mst_priority,
                 global.mst_priority)
    assert_equal(global.default_mst_root_priority,
                 global.mst_root_priority)
    assert_equal(global.default_mst_designated_priority,
                 global.mst_designated_priority)
    bddp = [%w(0-4,6,8-12 4096), %w(14 8192)]
    global.mst_priority = bddp
    global.mst_root_priority = bddp
    global.mst_designated_priority = bddp
    assert_equal(bddp, global.mst_priority)
    assert_equal(bddp, global.mst_root_priority)
    assert_equal(bddp, global.mst_designated_priority)
    global.mst_priority = global.default_mst_priority
    global.mst_root_priority = global.default_mst_root_priority
    global.mst_designated_priority = global.default_mst_designated_priority
    assert_equal(global.default_mst_priority,
                 global.mst_priority)
    assert_equal(global.default_mst_root_priority,
                 global.mst_root_priority)
    assert_equal(global.default_mst_designated_priority,
                 global.mst_designated_priority)
  end

  def test_get_set_mst_forward_time
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_forward_time = 25
    assert_equal(25, global.mst_forward_time)
    global.mst_forward_time =
      global.default_mst_forward_time
    assert_equal(global.default_mst_forward_time,
                 global.mst_forward_time)
  end

  def test_get_set_mst_hello_time
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_hello_time = 5
    assert_equal(5, global.mst_hello_time)
    global.mst_hello_time =
      global.default_mst_hello_time
    assert_equal(global.default_mst_hello_time,
                 global.mst_hello_time)
  end

  def test_get_set_mst_inst_vlan_map
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_inst_vlan_map = global.default_mst_inst_vlan_map
    assert_equal(global.default_mst_inst_vlan_map,
                 global.mst_inst_vlan_map)
    bddp = [%w(8 2-65), %w(14 200-300)]
    global.mst_inst_vlan_map = bddp
    assert_equal(bddp, global.mst_inst_vlan_map)
    global.mst_inst_vlan_map = global.default_mst_inst_vlan_map
    assert_equal(global.default_mst_inst_vlan_map,
                 global.mst_inst_vlan_map)
  end

  def test_get_set_mst_max_age
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_max_age = 35
    assert_equal(35, global.mst_max_age)
    global.mst_max_age =
      global.default_mst_max_age
    assert_equal(global.default_mst_max_age,
                 global.mst_max_age)
  end

  def test_get_set_mst_max_hops
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_max_hops = 200
    assert_equal(200, global.mst_max_hops)
    global.mst_max_hops =
      global.default_mst_max_hops
    assert_equal(global.default_mst_max_hops,
                 global.mst_max_hops)
  end

  def test_get_set_mst_name
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_name = 'nexus'
    assert_equal('nexus', global.mst_name)
    global.mst_name =
      global.default_mst_name
    assert_equal(global.default_mst_name,
                 global.mst_name)
  end

  def test_get_set_mst_revision
    global = StpGlobal.new('default')
    global.mode = 'mst'
    global.mst_revision = 34
    assert_equal(34, global.mst_revision)
    global.mst_revision =
      global.default_mst_revision
    assert_equal(global.default_mst_revision,
                 global.mst_revision)
  end

  def test_get_set_pathcost
    global = StpGlobal.new('default')
    global.pathcost = 'long'
    assert_equal('long', global.pathcost)
    global.pathcost =
      global.default_pathcost
    assert_equal(global.default_pathcost,
                 global.pathcost)
  end

  def test_get_set_vlan_forward_time
    global = StpGlobal.new('default')
    global.vlan_forward_time = global.default_vlan_forward_time
    assert_equal(global.default_vlan_forward_time,
                 global.vlan_forward_time)
    bddp = [%w(1-4,6,8-12 10), %w(14 8)]
    global.vlan_forward_time = bddp
    assert_equal(bddp, global.vlan_forward_time)
    global.vlan_forward_time = global.default_vlan_forward_time
    assert_equal(global.default_vlan_forward_time,
                 global.vlan_forward_time)
  end

  def test_get_set_vlan_hello_time
    global = StpGlobal.new('default')
    global.vlan_hello_time = global.default_vlan_hello_time
    assert_equal(global.default_vlan_hello_time,
                 global.vlan_hello_time)
    bddp = [%w(1-4,6,8-12 5), %w(14 8)]
    global.vlan_hello_time = bddp
    assert_equal(bddp, global.vlan_hello_time)
    global.vlan_hello_time = global.default_vlan_hello_time
    assert_equal(global.default_vlan_hello_time,
                 global.vlan_hello_time)
  end

  def test_get_set_vlan_max_age
    global = StpGlobal.new('default')
    global.vlan_max_age = global.default_vlan_max_age
    assert_equal(global.default_vlan_max_age,
                 global.vlan_max_age)
    bddp = [%w(1-4,6,8-12 40), %w(14 35)]
    global.vlan_max_age = bddp
    assert_equal(bddp, global.vlan_max_age)
    global.vlan_max_age = global.default_vlan_max_age
    assert_equal(global.default_vlan_max_age,
                 global.vlan_max_age)
  end

  def test_get_set_vlan_priorities
    global = StpGlobal.new('default')
    global.vlan_priority = global.default_vlan_priority
    global.vlan_root_priority = global.default_vlan_root_priority
    global.vlan_designated_priority = global.default_vlan_designated_priority
    assert_equal(global.default_vlan_priority,
                 global.vlan_priority)
    assert_equal(global.default_vlan_root_priority,
                 global.vlan_root_priority)
    assert_equal(global.default_vlan_designated_priority,
                 global.vlan_designated_priority)
    bddp = [%w(1-4,6,8-12 4096), %w(14 8192)]
    global.vlan_priority = bddp
    global.vlan_root_priority = bddp
    global.vlan_designated_priority = bddp
    assert_equal(bddp, global.vlan_priority)
    assert_equal(bddp, global.vlan_root_priority)
    assert_equal(bddp, global.vlan_designated_priority)
    global.vlan_priority = global.default_vlan_priority
    global.vlan_root_priority = global.default_vlan_root_priority
    global.vlan_designated_priority = global.default_vlan_designated_priority
    assert_equal(global.default_vlan_priority,
                 global.vlan_priority)
    assert_equal(global.default_vlan_root_priority,
                 global.vlan_root_priority)
    assert_equal(global.default_vlan_designated_priority,
                 global.vlan_designated_priority)
  end

  def test_interface_stp_bpdufilter_change
    @intf.stp_bpdufilter = 'enable'
    assert_equal('enable', @intf.stp_bpdufilter)
    @intf.stp_bpdufilter = 'disable'
    assert_equal('disable', @intf.stp_bpdufilter)
    @intf.stp_bpdufilter = @intf.default_stp_bpdufilter
    assert_equal(@intf.default_stp_bpdufilter,
                 @intf.stp_bpdufilter)
  end

  def test_interface_stp_bpduguard_change
    @intf.stp_bpduguard = 'enable'
    assert_equal('enable', @intf.stp_bpduguard)
    @intf.stp_bpduguard = 'disable'
    assert_equal('disable', @intf.stp_bpduguard)
    @intf.stp_bpduguard = @intf.default_stp_bpduguard
    assert_equal(@intf.default_stp_bpduguard,
                 @intf.stp_bpduguard)
  end

  def test_interface_stp_cost_change
    @intf.stp_cost = 2000
    assert_equal(2000, @intf.stp_cost)
    @intf.stp_cost = @intf.default_stp_cost
    assert_equal(@intf.default_stp_cost,
                 @intf.stp_cost)
  end

  def test_interface_stp_guard_change
    @intf.stp_guard = 'loop'
    assert_equal('loop', @intf.stp_guard)
    @intf.stp_guard = 'none'
    assert_equal('none', @intf.stp_guard)
    @intf.stp_guard = 'root'
    assert_equal('root', @intf.stp_guard)
    @intf.stp_guard = @intf.default_stp_guard
    assert_equal(@intf.default_stp_guard,
                 @intf.stp_guard)
  end

  def test_interface_stp_link_type_change
    @intf.stp_link_type = 'shared'
    assert_equal('shared', @intf.stp_link_type)
    @intf.stp_link_type = 'point-to-point'
    assert_equal('point-to-point', @intf.stp_link_type)
    @intf.stp_link_type = @intf.default_stp_link_type
    assert_equal(@intf.default_stp_link_type,
                 @intf.stp_link_type)
  end

  def test_interface_stp_port_priority_change
    @intf.stp_port_priority = 32
    assert_equal(32, @intf.stp_port_priority)
    @intf.stp_port_priority = @intf.default_stp_port_priority
    assert_equal(@intf.default_stp_port_priority,
                 @intf.stp_port_priority)
  end

  def test_interface_stp_port_type_change
    @intf.switchport_mode = :disabled
    @intf.switchport_mode = :trunk
    @intf.stp_port_type = 'edge'
    assert_equal('edge', @intf.stp_port_type)
    @intf.stp_port_type = 'edge trunk'
    assert_equal('edge trunk', @intf.stp_port_type)
    @intf.stp_port_type = 'network'
    assert_equal('network', @intf.stp_port_type)
    @intf.stp_port_type = 'normal'
    assert_equal('normal', @intf.stp_port_type)
    @intf.stp_port_type = @intf.default_stp_port_type
    assert_equal(@intf.default_stp_port_type,
                 @intf.stp_port_type)
  end

  def test_interface_stp_mst_cost_change
    @intf.stp_mst_cost = @intf.default_stp_mst_cost
    assert_equal(@intf.default_stp_mst_cost,
                 @intf.stp_mst_cost)
    mc = [%w(0,2-4,6,8-12 4500), %w(1 20000)]
    @intf.stp_mst_cost = mc
    assert_equal(mc, @intf.stp_mst_cost)
    @intf.stp_mst_cost = @intf.default_stp_mst_cost
    assert_equal(@intf.default_stp_mst_cost,
                 @intf.stp_mst_cost)
  end

  def test_interface_stp_mst_port_priority_change
    @intf.stp_mst_port_priority = @intf.default_stp_mst_port_priority
    assert_equal(@intf.default_stp_mst_port_priority,
                 @intf.stp_mst_port_priority)
    mpp = [%w(0,2-4,6,8-12 224), %w(1 32)]
    @intf.stp_mst_port_priority = mpp
    assert_equal(mpp, @intf.stp_mst_port_priority)
    @intf.stp_mst_port_priority = @intf.default_stp_mst_port_priority
    assert_equal(@intf.default_stp_mst_port_priority,
                 @intf.stp_mst_port_priority)
  end

  def test_interface_stp_vlan_cost_change
    @intf.stp_vlan_cost = @intf.default_stp_vlan_cost
    assert_equal(@intf.default_stp_vlan_cost,
                 @intf.stp_vlan_cost)
    vc = [%w(2-4,6,8-12 4500), %w(14 20000)]
    @intf.stp_vlan_cost = vc
    assert_equal(vc, @intf.stp_vlan_cost)
    @intf.stp_vlan_cost = @intf.default_stp_vlan_cost
    assert_equal(@intf.default_stp_vlan_cost,
                 @intf.stp_vlan_cost)
  end

  def test_interface_stp_vlan_port_priority_change
    @intf.stp_vlan_port_priority = @intf.default_stp_vlan_port_priority
    assert_equal(@intf.default_stp_vlan_port_priority,
                 @intf.stp_vlan_port_priority)
    vpp = [%w(2-4,6,8-12 224), %w(14 32)]
    @intf.stp_vlan_port_priority = vpp
    assert_equal(vpp, @intf.stp_vlan_port_priority)
    @intf.stp_vlan_port_priority = @intf.default_stp_vlan_port_priority
    assert_equal(@intf.default_stp_vlan_port_priority,
                 @intf.stp_vlan_port_priority)
  end

  def test_interface_stp_props_switchport_disabled
    @intf.switchport_enable(false)
    proplist = {
      'bpdufilter'         => 'enable',
      'cost'               => 2000,
      'guard'              => 'loop',
      'link_type'          => 'shared',
      'mst_cost'           => [%w(0,2-4,6,8-12 4500), %w(1 20000)],
      'mst_port_priority'  => [%w(0,2-4,6,8-12 224), %w(1 32)],
      'port_priority'      => 32,
      'vlan_cost'          => [%w(2-4,6,8-12 4500), %w(14 20000)],
      'vlan_port_priority' => [%w(2-4,6,8-12 224), %w(14 32)],
    }
    proplist.each do |k, v|
      assert_raises(RuntimeError, 'foo') do
        @intf.send("stp_#{k}=", v)
      end
    end
  end
end
