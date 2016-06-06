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
require_relative '../lib/cisco_node_utils/router_ospf_area'

# TestRouterOspfArea - Minitest for RouterOspfArea node utility class
class TestRouterOspfArea < CiscoTestCase
  @skip_unless_supported = 'ospf'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_ospfs if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    remove_all_ospfs
    super
  end

  def test_ospf_area_properties
    ospf_area = RouterOspfArea.new('green', 'testvrf1', '5.5.5.5')
    # Check authentication property
    assert_equal(ospf_area.default_authentication, ospf_area.authentication,
                 'Error: Area Authentication is not initialized to default')
    ospf_area.authentication = 'md5'
    assert_equal('md5', ospf_area.authentication,
                 'Error: Area Authentication is not md5')
    # Check default-cost property
    assert_equal(ospf_area.default_cost, ospf_area.cost,
                 'Error: Area default-cost is not initialized to default')
    ospf_area.cost = 10
    assert_equal(10, ospf_area.cost,
                 'Error: Area default-cost has not been set to 10')
    # Check filter_list_in property
    assert_equal(ospf_area.default_filter_list_in, ospf_area.filter_list_in,
                 'Error: Area filter_list_in is not initialized to default')
    ospf_area.filter_list_in = 'test_map_in'
    assert_equal('test_map_in', ospf_area.filter_list_in,
                 'Error: Area filter_list_in has not been set to test_map_in')
    # Check filter_list_out property
    assert_equal(ospf_area.default_filter_list_out, ospf_area.filter_list_out,
                 'Error: Area filter_list_out is not initialized to default')
    ospf_area.filter_list_out = 'test_map_out'
    assert_equal('test_map_out', ospf_area.filter_list_out,
                 'Error: Area filter_list_out has not been set to test_map_out')
    ospf_area.destroy
  end
end
