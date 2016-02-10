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
require_relative '../lib/cisco_node_utils/cisco_cmn_utils'
require_relative '../lib/cisco_node_utils/fabricpath_global'

include Cisco

# TestFabricpathGlobal - Minitest for Fabricpath Global node utils
class TestFabricpathGlobal < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('fabricpath', 'feature').default_value.nil?
    no_feature_fabricpath
  end

  def teardown
    # teardown runs at the end of each test
    no_feature_fabricpath
    super
  end

  def no_feature_fabricpath
    # Turn the feature off for a clean test.
    config('no feature-set fabricpath')
  end

  def n5k6k_platforms?
    /N[56]K/ =~ node.product_id
  end

  # TESTS

  def test_global_collection_empty
    globals = FabricpathGlobal.globals
    assert_equal(true, globals.empty?,
                 'Globals should be empty for this test')
  end

  def test_global_create
    @global = FabricpathGlobal.new('default')
    assert_equal(true, @global.name == 'default',
                 "Global name not set correctly #{@global.name}")
    assert_equal(:enabled, FabricpathGlobal.fabricpath_feature,
                 'Fabricpath feature should have been enabled')
    refute(FabricpathGlobal.globals.empty?,
           'Globals should not be empty after create')
  end

  def test_global_destroy
    # create and test again
    test_global_create
    @global.destroy
    # now it should be wiped out
    test_global_collection_empty
  end

  def test_aggregate_multicast_routes
    return if n5k6k_platforms?
    @global = FabricpathGlobal.new('default')
    @global.aggregate_multicast_routes = true
    assert(@global.aggregate_multicast_routes,
           'Aggregate multicast routes not set')
    @global.aggregate_multicast_routes = false
    refute(@global.aggregate_multicast_routes,
           'Aggregate multicast routes not reset')
  end

  def test_allocate_delay
    @global = FabricpathGlobal.new('default')
    # test default value
    assert_equal(@global.default_allocate_delay,
                 @global.allocate_delay,
                 'Default allocate_delay not set correctly')
    @global.allocate_delay = 20
    assert_equal(20, @global.allocate_delay,
                 'allocate_delay not set to 20')
  end

  def test_graceful_merge
    @global = FabricpathGlobal.new('default')
    # test default value
    assert_equal(:enable, @global.graceful_merge,
                 'Default graceful_merge not set correctly')
    @global.graceful_merge = :disable
    assert_equal(:disable, @global.graceful_merge,
                 'graceful merge not set to disable')
  end

  def test_linkup_delay_all
    @global = FabricpathGlobal.new('default')
    # test default value
    assert_equal(@global.default_linkup_delay,
                 @global.linkup_delay,
                 'Default linkup_delay not set correctly')
    @global.linkup_delay = 25
    assert_equal(25, @global.linkup_delay,
                 'linkup_delay not set to 25')

    return if n5k6k_platforms?

    refute(@global.linkup_delay_always,
           'linkup_delay_always should not be set by default')
    @global.linkup_delay_always = true
    assert(@global.linkup_delay_always,
           'linkup_delay_always is not getting set')

    @global.linkup_delay_enable = true
    @global.linkup_delay_enable = false
    refute(@global.linkup_delay_enable,
           'linkup_delay is not getting disabled')
  end

  def test_loadbalance_algorithm
    @global = FabricpathGlobal.new('default')
    # test default value
    check_val = n5k6k_platforms? ? 'source-destination' : 'symmetric'
    assert_equal(check_val, @global.loadbalance_algorithm,
                 "default algo should be #{check_val} but is
                  #{@global.loadbalance_algorithm}")
    @global.loadbalance_algorithm = 'source'
    assert_equal('source', @global.loadbalance_algorithm,
                 'algo not getting set to source-destination')
  end

  def test_loadbalance_multicast
    return if n5k6k_platforms?
    @global = FabricpathGlobal.new('default')
    # test default values first
    assert_equal(@global.default_loadbalance_multicast_rotate,
                 @global.loadbalance_multicast_rotate,
                 "default mcast rotate should be 6
                  but is #{@global.loadbalance_multicast_rotate}")
    assert(@global.loadbalance_multicast_has_vlan,
           "default mcast include-vlan should be true
           but is #{@global.loadbalance_multicast_has_vlan}")
    @global.send(:loadbalance_multicast=, 3, false)
    assert_equal(3, @global.loadbalance_multicast_rotate,
                 "mcast rotate should now be 3
                  but is #{@global.loadbalance_multicast_rotate}")
    refute(@global.loadbalance_multicast_has_vlan,
           "mcast include-vlan should now be false
           but is #{@global.loadbalance_multicast_has_vlan}")
  end

  def test_loadbalance_unicast
    @global = FabricpathGlobal.new('default')
    # test default values first
    assert_equal(@global.default_loadbalance_unicast_layer,
                 @global.loadbalance_unicast_layer,
                 "default unicast layer should be mixed
                  but is #{@global.loadbalance_unicast_layer}")
    assert_equal(@global.default_loadbalance_unicast_rotate,
                 @global.loadbalance_unicast_rotate,
                 "default unicast rotate not set correctly
                  but is set to #{@global.loadbalance_unicast_rotate}") unless
                 n5k6k_platforms?
    assert(@global.loadbalance_unicast_has_vlan,
           "default unicast include-vlan should be true
           but is #{@global.loadbalance_unicast_has_vlan}")
    @global.send(:loadbalance_unicast=, 'layer4', 3, false)
    assert_equal('layer4', @global.loadbalance_unicast_layer,
                 "unicast layer should be layer4
                  but is #{@global.loadbalance_unicast_layer}")
    assert_equal(3, @global.loadbalance_unicast_rotate,
                 "unicast rotate should now be 3
                  but is #{@global.loadbalance_unicast_rotate}") unless
                 n5k6k_platforms?
    refute(@global.loadbalance_unicast_has_vlan,
           "unicast include-vlan should now be false
           but is #{@global.loadbalance_unicast_has_vlan}")
  end

  def test_mode
    @global = FabricpathGlobal.new('default')
    # test default value
    assert_equal(@global.default_mode, @global.mode,
                 "default mode should be normal but is #{@global.mode}")
    @global.mode = 'transit'
    assert_equal('transit', @global.mode,
                 'mode not getting set to transit')
    @global.mode = 'normal'
    assert_equal('normal', @global.mode,
                 'mode not getting set to transit')
  end

  def test_switch_id
    @global = FabricpathGlobal.new('default')
    # auto_id = @global.switch_id
    @global.switch_id = 100
    assert_equal(100, @global.switch_id,
                 'switchid not getting set to 100')
  end

  def test_transition_delay
    @global = FabricpathGlobal.new('default')
    # test default value
    assert_equal(@global.default_transition_delay,
                 @global.transition_delay,
                 'Default allocate_delay not set correctly')
    @global.transition_delay = 20
    assert_equal(20, @global.transition_delay,
                 'transition_delay not set to 20')
  end

  def test_ttl_multicast
    return if n5k6k_platforms?
    @global = FabricpathGlobal.new('default')
    # test default value
    assert_equal(@global.default_ttl_multicast,
                 @global.ttl_multicast,
                 'Default multicast ttl not set correctly')
    @global.ttl_multicast = 16
    assert_equal(16, @global.ttl_multicast,
                 'multicast ttl not getting set to 16')
  end

  def test_ttl_unicast
    return if n5k6k_platforms?
    @global = FabricpathGlobal.new('default')
    # test default value
    assert_equal(@global.default_ttl_unicast,
                 @global.ttl_unicast,
                 'Default unicast ttl not set correctly')
    @global.ttl_unicast = 40
    assert_equal(40, @global.ttl_unicast,
                 'unicast ttl not getting set to 40')
  end
end
