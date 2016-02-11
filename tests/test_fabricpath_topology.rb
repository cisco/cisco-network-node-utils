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
require_relative '../lib/cisco_node_utils/fabricpath_topology'

include Cisco

# TestFabricpathTopo - Minitest for Fabricpath Topo node utils
class TestFabricpathTopo < CiscoTestCase
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
    config('no install feature-set fabricpath')
  end

  # TESTS

  def test_topo_create
    @topo = FabricpathTopo.new('1')
    @topo.topo_name = 'Topo-1'
    assert_equal('Topo-1', @topo.topo_name,
                 "Topo name not set correctly #{@topo.topo_name}")
    assert_equal(:enabled, @topo.fabricpath_feature,
                 'Fabricpath feature should have been enabled')
    topos = FabricpathTopo.topos
    assert_equal(2, topos.length,
                 'Number of Topos should be 2')
  end

  def test_topo_destroy
    # create and test again
    test_topo_create
    # puts "deleting Topo #{@topo.topo_name}"
    @topo.destroy
    # now it should be wiped out
    topos = FabricpathTopo.topos
    assert_equal(1, topos.length,
                 'Number of Topos should be 1 (default)')
  end

  def test_invalid_topo_id
    e = assert_raises(CliError) { FabricpathTopo.new('64') }
    assert_match(/Invalid number.* range/, e.message)
  end

  def test_member_vlans
    @topo = FabricpathTopo.new('25')
    topos = FabricpathTopo.topos
    default_topo = topos['0']
    default_topo_vlans = default_topo.member_vlans.first
    # puts "vlans in default topo is #{default_topo_vlans}"
    assert_equal('1..4096', default_topo_vlans,
                 'default topo should have all VLANS')
    @topo.member_vlans = ['2..10', '100', '500']
    topo25_vlans = @topo.member_vlans.join(',')
    # puts "Topo #{@topo.topo_name} member vlans #{topo25_vlans}"
    assert_equal('2..10,100,500', topo25_vlans,
                 'Topo 25 not getting set with member vlans')
    default_topo_vlans = default_topo.member_vlans.join(',')
    # puts "vlans in default topo is #{default_topo_vlans}"
    assert_equal('1,11..99,101..499,501..4096', default_topo_vlans,
                 'default topo should now have the set
                  1,11..99,101..499,501..4096')
  end

  def test_member_vlans_invalid
    @topo = FabricpathTopo.new('25')
    e = assert_raises(RuntimeError) { @topo.member_vlans = ['1..4095'] }
    assert_match(%r{Invalid value/range}, e.message)
  end
end
