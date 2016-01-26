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
require_relative '../lib/cisco_node_utils/stp_global'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestStpGlobal < CiscoTestCase
  # TESTS

  DEFAULT_NAME = 'default'

  def setup
    super
    config 'no spanning-tree mode'
    config 'system bridge-domain none' if n7k_platform?
  end

  def teardown
    config 'no spanning-tree mode'
    config 'system bridge-domain none' if n7k_platform?
    super
  end

  def n7k_platform?
    /N7/ =~ node.product_id
  end

  def n9k_platform?
    /N(3|9)/ =~ node.product_id
  end

  def n6k_platform?
    /N(5|6)/ =~ node.product_id
  end

  def create_stp_global(name=DEFAULT_NAME)
    StpGlobal.new(name)
  end

  def test_bd_forward_time_change
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n9k_platform?
    @global = create_stp_global
    config 'system bridge-domain all'
    bdft = [['2-4,6,8-12', '4'], %w(14 30)]
    @global.bd_forward_time = bdft
    assert_equal(bdft, @global.bd_forward_time)
    bdft = [['2-42', '26'], ['83-92,1000-2300', '20'],
            ['3000-3960', '16']]
    @global.bd_forward_time = bdft
    assert_equal(bdft, @global.bd_forward_time)
    @global.bd_forward_time = @global.default_bd_forward_time
    assert_equal(@global.default_bd_forward_time,
                 @global.bd_forward_time)
  end

  def test_bd_hello_time_change
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n9k_platform?
    @global = create_stp_global
    config 'system bridge-domain all'
    bdft = [['2-4,6,8-12', '1'], %w(14 10)]
    @global.bd_hello_time = bdft
    assert_equal(bdft, @global.bd_hello_time)
    bdft = [['2-42', '6'], ['83-92,1000-2300', '9'],
            ['3000-3960', '3']]
    @global.bd_hello_time = bdft
    assert_equal(bdft, @global.bd_hello_time)
    @global.bd_hello_time = @global.default_bd_hello_time
    assert_equal(@global.default_bd_hello_time,
                 @global.bd_hello_time)
  end

  def test_bd_max_age_change
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n9k_platform?
    @global = create_stp_global
    config 'system bridge-domain all'
    bdft = [['2-4,6,8-12', '10'], %w(14 40)]
    @global.bd_max_age = bdft
    assert_equal(bdft, @global.bd_max_age)
    bdft = [['2-42', '6'], ['83-92,1000-2300', '29'],
            ['3000-3960', '13']]
    @global.bd_max_age = bdft
    assert_equal(bdft, @global.bd_max_age)
    @global.bd_max_age = @global.default_bd_max_age
    assert_equal(@global.default_bd_max_age,
                 @global.bd_max_age)
  end

  def test_bd_priorities_change
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n9k_platform?
    @global = create_stp_global
    config 'system bridge-domain all'
    bdft = [['2-4,6,8-12', '4096'], %w(14 8192)]
    @global.bd_priority = bdft
    @global.bd_root_priority = bdft
    @global.bd_designated_priority = bdft
    assert_equal(bdft, @global.bd_priority)
    assert_equal(bdft, @global.bd_root_priority)
    assert_equal(bdft, @global.bd_designated_priority)
    bdft = [['2-42', '40960'], ['83-92,1000-2300', '53248'],
            ['3000-3960', '16384']]
    @global.bd_priority = bdft
    @global.bd_root_priority = bdft
    @global.bd_designated_priority = bdft
    assert_equal(bdft, @global.bd_priority)
    assert_equal(bdft, @global.bd_root_priority)
    assert_equal(bdft, @global.bd_designated_priority)
    @global.bd_priority = @global.default_bd_priority
    @global.bd_root_priority = @global.default_bd_root_priority
    @global.bd_designated_priority = @global.default_bd_designated_priority
    assert_equal(@global.default_bd_priority,
                 @global.bd_priority)
    assert_equal(@global.default_bd_root_priority,
                 @global.bd_root_priority)
    assert_equal(@global.default_bd_designated_priority,
                 @global.bd_designated_priority)
  end

  def test_get_set_bpdufilter
    @global = create_stp_global
    @global.bpdufilter = true
    assert_equal(true, @global.bpdufilter)
    @global.bpdufilter =
      @global.default_bpdufilter
    assert_equal(@global.default_bpdufilter,
                 @global.bpdufilter)
  end

  def test_get_set_bpduguard
    @global = create_stp_global
    @global.bpduguard = true
    assert_equal(true, @global.bpduguard)
    @global.bpduguard =
      @global.default_bpduguard
    assert_equal(@global.default_bpduguard,
                 @global.bpduguard)
  end

  def test_get_set_bridge_assurance
    @global = create_stp_global
    @global.bridge_assurance = false
    assert_equal(false, @global.bridge_assurance)
    @global.bridge_assurance =
      @global.default_bridge_assurance
    assert_equal(@global.default_bridge_assurance,
                 @global.bridge_assurance)
  end

  def test_get_set_domain
    skip('Platform does not support this property') if n9k_platform?
    @global = create_stp_global
    @global.domain = 100
    assert_equal(100, @global.domain)
    @global.domain =
      @global.default_domain
    assert_equal(@global.default_domain,
                 @global.domain)
  end

  def test_get_set_fcoe
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n7k_platform?
    @global = create_stp_global
    @global.fcoe = false
    assert_equal(false, @global.fcoe)
    @global.fcoe =
      @global.default_fcoe
    assert_equal(@global.default_fcoe,
                 @global.fcoe)
  end

  def test_get_set_loopguard
    @global = create_stp_global
    @global.loopguard = true
    assert_equal(true, @global.loopguard)
    @global.loopguard =
      @global.default_loopguard
    assert_equal(@global.default_loopguard,
                 @global.loopguard)
  end

  def test_get_set_mode
    @global = create_stp_global
    @global.mode = 'mst'
    assert_equal('mst', @global.mode)
    @global.mode =
      @global.default_mode
    assert_equal(@global.default_mode,
                 @global.mode)
  end

  def test_get_set_mst_priorities
    @global = create_stp_global
    @global.mode = 'mst'
    bddp = [['0-4,6,8-12', '4096'], %w(14 8192)]
    @global.mst_priority = bddp
    @global.mst_root_priority = bddp
    @global.mst_designated_priority = bddp
    assert_equal(bddp, @global.mst_priority)
    assert_equal(bddp, @global.mst_root_priority)
    assert_equal(bddp, @global.mst_designated_priority)
    bddp = [['2-42', '40960'], ['83-92,1000-2300', '53248'],
            ['3000-4080', '16384']]
    @global.mst_priority = bddp
    @global.mst_root_priority = bddp
    @global.mst_designated_priority = bddp
    assert_equal(bddp, @global.mst_priority)
    assert_equal(bddp, @global.mst_root_priority)
    assert_equal(bddp, @global.mst_designated_priority)
    @global.mst_priority = @global.default_mst_priority
    @global.mst_root_priority = @global.default_mst_root_priority
    @global.mst_designated_priority = @global.default_mst_designated_priority
    assert_equal(@global.default_mst_priority,
                 @global.mst_priority)
    assert_equal(@global.default_mst_root_priority,
                 @global.mst_root_priority)
    assert_equal(@global.default_mst_designated_priority,
                 @global.mst_designated_priority)
  end

  def test_get_set_mst_forward_time
    @global = create_stp_global
    @global.mode = 'mst'
    @global.mst_forward_time = 25
    assert_equal(25, @global.mst_forward_time)
    @global.mst_forward_time =
      @global.default_mst_forward_time
    assert_equal(@global.default_mst_forward_time,
                 @global.mst_forward_time)
  end

  def test_get_set_mst_hello_time
    @global = create_stp_global
    @global.mode = 'mst'
    @global.mst_hello_time = 5
    assert_equal(5, @global.mst_hello_time)
    @global.mst_hello_time =
      @global.default_mst_hello_time
    assert_equal(@global.default_mst_hello_time,
                 @global.mst_hello_time)
  end

  def test_get_set_mst_inst_vlan_map
    @global = create_stp_global
    @global.mode = 'mst'
    bddp = [['8', '2-65'], ['14', '200-300']]
    @global.mst_inst_vlan_map = bddp
    assert_equal(bddp, @global.mst_inst_vlan_map)
    bddp = [['2', '6-47'], ['92', '120-400'],
            ['3000', '1000-3200']]
    @global.mst_inst_vlan_map = bddp
    assert_equal(bddp, @global.mst_inst_vlan_map)
    @global.mst_inst_vlan_map = @global.default_mst_inst_vlan_map
    assert_equal(@global.default_mst_inst_vlan_map,
                 @global.mst_inst_vlan_map)
  end

  def test_get_set_mst_max_age
    @global = create_stp_global
    @global.mode = 'mst'
    @global.mst_max_age = 35
    assert_equal(35, @global.mst_max_age)
    @global.mst_max_age =
      @global.default_mst_max_age
    assert_equal(@global.default_mst_max_age,
                 @global.mst_max_age)
  end

  def test_get_set_mst_max_hops
    @global = create_stp_global
    @global.mode = 'mst'
    @global.mst_max_hops = 200
    assert_equal(200, @global.mst_max_hops)
    @global.mst_max_hops =
      @global.default_mst_max_hops
    assert_equal(@global.default_mst_max_hops,
                 @global.mst_max_hops)
  end

  def test_get_set_mst_name
    @global = create_stp_global
    @global.mode = 'mst'
    @global.mst_name = 'nexus'
    assert_equal('nexus', @global.mst_name)
    @global.mst_name =
      @global.default_mst_name
    assert_equal(@global.default_mst_name,
                 @global.mst_name)
  end

  def test_get_set_mst_revision
    @global = create_stp_global
    @global.mode = 'mst'
    @global.mst_revision = 34
    assert_equal(34, @global.mst_revision)
    @global.mst_revision =
      @global.default_mst_revision
    assert_equal(@global.default_mst_revision,
                 @global.mst_revision)
  end

  def test_get_set_pathcost
    @global = create_stp_global
    @global.pathcost = 'long'
    assert_equal('long', @global.pathcost)
    @global.pathcost =
      @global.default_pathcost
    assert_equal(@global.default_pathcost,
                 @global.pathcost)
  end

  def test_get_set_vlan_forward_time
    @global = create_stp_global
    bddp = [['1-4,6,8-12', '10'], %w(14 8)]
    @global.vlan_forward_time = bddp
    assert_equal(bddp, @global.vlan_forward_time)
    bddp = [['1-42', '19'], ['83-92,1000-2300', '13'],
            ['3000-3700', '16']]
    @global.vlan_forward_time = bddp
    assert_equal(bddp, @global.vlan_forward_time)
    @global.vlan_forward_time = @global.default_vlan_forward_time
    assert_equal(@global.default_vlan_forward_time,
                 @global.vlan_forward_time)
  end

  # on n6k the 'no' cmd for vlan_hello_time is not working so this will fail
  def test_get_set_vlan_hello_time
    @global = create_stp_global
    bddp = [['1-4,6,8-12', '5'], %w(14 8)]
    @global.vlan_hello_time = bddp
    assert_equal(bddp, @global.vlan_hello_time)
    bddp = [['1-42', '10'], ['83-92,1000-2300', '6'],
            ['3000-3700', '3']]
    @global.vlan_hello_time = bddp
    assert_equal(bddp, @global.vlan_hello_time)
    @global.vlan_hello_time = @global.default_vlan_hello_time
    assert_equal(@global.default_vlan_hello_time,
                 @global.vlan_hello_time)
  end

  def test_get_set_vlan_max_age
    @global = create_stp_global
    bddp = [['1-4,6,8-12', '40'], %w(14 35)]
    @global.vlan_max_age = bddp
    assert_equal(bddp, @global.vlan_max_age)
    bddp = [['1-42', '21'], ['83-92,1000-2300', '13'],
            ['3000-3700', '16']]
    @global.vlan_max_age = bddp
    assert_equal(bddp, @global.vlan_max_age)
    @global.vlan_max_age = @global.default_vlan_max_age
    assert_equal(@global.default_vlan_max_age,
                 @global.vlan_max_age)
  end

  def test_get_set_vlan_priorities
    @global = create_stp_global
    bddp = [['1-4,6,8-12', '4096'], %w(14 8192)]
    @global.vlan_priority = bddp
    @global.vlan_root_priority = bddp
    @global.vlan_designated_priority = bddp
    assert_equal(bddp, @global.vlan_priority)
    assert_equal(bddp, @global.vlan_root_priority)
    assert_equal(bddp, @global.vlan_designated_priority)
    bddp = [['1-42', '40960'], ['83-92,1000-2300', '53248'],
            ['3000-3700', '16384']]
    @global.vlan_priority = bddp
    @global.vlan_root_priority = bddp
    @global.vlan_designated_priority = bddp
    assert_equal(bddp, @global.vlan_priority)
    assert_equal(bddp, @global.vlan_root_priority)
    assert_equal(bddp, @global.vlan_designated_priority)
    @global.vlan_priority = @global.default_vlan_priority
    @global.vlan_root_priority = @global.default_vlan_root_priority
    @global.vlan_designated_priority = @global.default_vlan_designated_priority
    assert_equal(@global.default_vlan_priority,
                 @global.vlan_priority)
    assert_equal(@global.default_vlan_root_priority,
                 @global.vlan_root_priority)
    assert_equal(@global.default_vlan_designated_priority,
                 @global.vlan_designated_priority)
  end
end
