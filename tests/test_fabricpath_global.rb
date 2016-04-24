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
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/platform'

include Cisco

# TestFabricpathGlobal - Minitest for Fabricpath Global node utils
class TestFabricpathGlobal < CiscoTestCase
  @skip_unless_supported = 'fabricpath'

  def setup
    # setup runs at the beginning of each test
    super
    fabricpath_testenv_setup
    no_feature_fabricpath
  end

  def teardown
    # teardown runs at the end of each test
    no_feature_fabricpath
    super
  end

  def no_feature_fabricpath
    fg = FabricpathGlobal.globals
    fg.each { |_key, elem| elem.destroy } unless fg.empty?
  end

  #  def no_feature_fabricpath
  #    # Turn the feature off for a clean test.
  #    config('no feature-set fabricpath')
  #  end

  # TESTS

  def test_create_destroy
    assert_empty(FabricpathGlobal.globals)

    # create
    fg = FabricpathGlobal.new('default')
    assert_equal('default', fg.name)
    assert_equal(:enabled, FabricpathGlobal.fabricpath_feature)
    refute_empty(FabricpathGlobal.globals)

    # destroy
    fg.destroy
    assert_empty(FabricpathGlobal.globals)
  end

  def test_aggregate_multicast_routes
    fg = FabricpathGlobal.new('default')
    if validate_property_excluded?('fabricpath', 'aggregate_multicast_routes')
      assert_raises(Cisco::UnsupportedError) do
        fg.aggregate_multicast_routes = true
      end
      return
    end

    fg = FabricpathGlobal.new('default')
    fg.aggregate_multicast_routes = true
    assert(fg.aggregate_multicast_routes,
           'aggregate_multicast_routes: Expected: true')

    fg.aggregate_multicast_routes = false
    refute(fg.aggregate_multicast_routes,
           'aggregate_multicast_routes: Expected: false')
  end

  def test_allocate_delay
    fg = FabricpathGlobal.new('default')
    assert_equal(fg.default_allocate_delay, fg.allocate_delay)

    fg.allocate_delay = 20
    assert_equal(20, fg.allocate_delay)
  end

  def test_graceful_merge
    fg = FabricpathGlobal.new('default')
    assert_equal(fg.default_graceful_merge, fg.graceful_merge)

    fg.graceful_merge = :disable
    assert_equal(:disable, fg.graceful_merge)
  end

  def test_linkup_delay_all
    fg = FabricpathGlobal.new('default')
    assert_equal(fg.default_linkup_delay, fg.linkup_delay)

    fg.linkup_delay = 25
    assert_equal(25, fg.linkup_delay)

    if validate_property_excluded?('fabricpath', 'linkup_delay_always')
      assert_raises(Cisco::UnsupportedError) { fg.linkup_delay_always = true }
    else
      assert_equal(fg.default_linkup_delay_always, fg.linkup_delay_always)
      fg.linkup_delay_always = true
      assert(fg.linkup_delay_always, 'linkup_delay_always: Expected: true')
      fg.linkup_delay_always = false
      refute(fg.linkup_delay_always, 'linkup_delay_always: Expected: false')
    end

    if validate_property_excluded?('fabricpath', 'linkup_delay_enable')
      assert_raises(Cisco::UnsupportedError) { fg.linkup_delay_enable = true }
      return
    end

    assert_equal(fg.default_linkup_delay_enable, fg.linkup_delay_enable)
    fg.linkup_delay_enable = true
    assert(fg.linkup_delay_enable, 'linkup_delay_enable: Expected: true')
    fg.linkup_delay_enable = false
    refute(fg.linkup_delay_enable, 'linkup_delay_enable: Expected: false')
  end

  def test_loadbalance_algorithm
    fg = FabricpathGlobal.new('default')
    assert_equal(fg.default_loadbalance_algorithm, fg.loadbalance_algorithm)

    fg.loadbalance_algorithm = 'source'
    assert_equal('source', fg.loadbalance_algorithm)
    if validate_property_excluded?('fabricpath',
                                   'loadbalance_algorithm_symmetric_support')
      assert_nil(fg.loadbalance_algorithm_symmetric_support)
      return
    end
    fg.loadbalance_algorithm = 'symmetric'
    assert_equal('symmetric', fg.loadbalance_algorithm)
  end

  def test_loadbalance_multicast
    # loadbalance_multicast= is a custom setter that takes 2 args:
    #   rotate, has_vlan
    fg = FabricpathGlobal.new('default')
    if validate_property_excluded?('fabricpath',
                                   'loadbalance_multicast_set')
      assert_raises(Cisco::UnsupportedError) do
        (fg.send(:loadbalance_multicast=, 0, 0))
      end
      return
    end

    # default_loadbalance_multicast_rotate: n/a
    assert(fg.loadbalance_multicast_has_vlan,
           'loadbalance_multicast_has_vlan: Expected: true')

    fg.send(:loadbalance_multicast=, 3, false)
    assert_equal(3, fg.loadbalance_multicast_rotate)
    refute(fg.loadbalance_multicast_has_vlan,
           'loadbalance_multicast_has_vlan: Expected: false')
  end

  def test_loadbalance_unicast
    # loadbalance_unicast= is a custom setter that takes up to 3 args:
    #   layer, rotate, has_vlan (rotate is not supported on some plats)

    fg = FabricpathGlobal.new('default')
    assert_equal(fg.default_loadbalance_unicast_layer,
                 fg.loadbalance_unicast_layer)

    # default_loadbalance_unicast_rotate: n/a
    assert_equal(fg.default_loadbalance_unicast_has_vlan,
                 fg.loadbalance_unicast_has_vlan)

    fg.send(:loadbalance_unicast=, 'layer4', 3, false)
    assert_equal('layer4', fg.loadbalance_unicast_layer)
    unless validate_property_excluded?('fabricpath',
                                       'loadbalance_unicast_rotate')
      assert_equal(3, fg.loadbalance_unicast_rotate)
    end
    refute(fg.loadbalance_unicast_has_vlan,
           'loadbalance_unicast_has_vlan: Expected: false')
  end

  def test_mode
    fg = FabricpathGlobal.new('default')
    assert_equal(fg.default_mode, fg.mode)

    fg.mode = 'transit'
    assert_equal('transit', fg.mode)
    fg.mode = 'normal'
    assert_equal('normal', fg.mode)
  end

  def test_switch_id
    fg = FabricpathGlobal.new('default')
    # auto_id = fg.switch_id
    # switch_id does not have a default
    fg.switch_id = 100
    assert_equal(100, fg.switch_id)
  end

  def test_transition_delay
    fg = FabricpathGlobal.new('default')
    assert_equal(fg.default_transition_delay, fg.transition_delay)

    fg.transition_delay = 20
    assert_equal(20, fg.transition_delay)
  end

  def test_ttl_multicast
    fg = FabricpathGlobal.new('default')
    if validate_property_excluded?('fabricpath', 'ttl_multicast')
      assert_raises(Cisco::UnsupportedError) { fg.ttl_multicast = 40 }
      return
    end

    assert_equal(fg.default_ttl_multicast, fg.ttl_multicast)
    fg.ttl_multicast = 16
    assert_equal(16, fg.ttl_multicast)
  end

  def test_ttl_unicast
    fg = FabricpathGlobal.new('default')
    if validate_property_excluded?('fabricpath', 'ttl_unicast')
      assert_raises(Cisco::UnsupportedError) { fg.ttl_unicast = 40 }
      return
    end
    assert_equal(fg.default_ttl_unicast, fg.ttl_unicast)
    fg.ttl_unicast = 40
    assert_equal(40, fg.ttl_unicast)
  end

  def test_interface_switchport_mode
    i = Interface.new(interfaces[0])
    i.switchport_mode = :fabricpath
    assert_equal(:fabricpath, i.switchport_mode)

    i.switchport_mode = :trunk
    assert_equal(:trunk, i.switchport_mode)
    config("default interface #{interfaces[0]}")
  end
end
