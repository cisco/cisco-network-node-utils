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
  @skip_unless_supported = 'fabricpath_topology'

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
    config_no_warn('no feature-set fabricpath')
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
    assert_equal(1, topos.length,
                 'Number of Topos should be 1')
  end

  def test_topo_destroy
    # create and test again
    @topo = FabricpathTopo.new('2')
    @topo.destroy
    # now it should be wiped out
    topos = FabricpathTopo.topos
    assert_equal(0, topos.length,
                 'Number of Topos should be 0 (only default)')
  end

  def test_member_vlans
    @topo = FabricpathTopo.new('25')
    @topo.topo_name = 'Topo-25'
    @topo.member_vlans = '2-10, 100, 500'
    topo25_vlans = @topo.member_vlans
    # puts "Topo #{@topo.topo_name} member vlans #{topo25_vlans}"
    assert_equal('2-10,100,500', topo25_vlans,
                 'Topo 25 not getting set with member vlans')
  end
end
