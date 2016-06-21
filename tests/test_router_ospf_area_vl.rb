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
require_relative '../lib/cisco_node_utils/router_ospf'
require_relative '../lib/cisco_node_utils/router_ospf_vrf'
require_relative '../lib/cisco_node_utils/router_ospf_area_vl'

# TestRouterOspfAreaVirtualLink - Minitest for RouterOspfAreaVirtualLink
# node utility class
class TestRouterOspfAreaVirtualLink < CiscoTestCase
  @skip_unless_supported = 'ospf_area_vl'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_ospfs if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    remove_all_ospfs
    config 'no feature ospf'
    super
  end

  def create_routerospfarea_default_virtual_link(router='Wolfpack',
                                                 name='default',
                                                 area_id='1.1.1.1',
                                                 vl='2.2.2.2')
    RouterOspfAreaVirtualLink.new(router, name, area_id, vl)
  end

  def create_routerospfarea_vrf_virtual_link(router='Wolfpack',
                                             name='blue',
                                             area_id='1450',
                                             vl='3.3.3.3')
    RouterOspfAreaVirtualLink.new(router, name, area_id, vl)
  end

  def test_collection_size
    dvl1 = create_routerospfarea_default_virtual_link
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['default'].size)
    dvl2 = create_routerospfarea_default_virtual_link('Wolfpack', 'default',
                                                      '1.1.1.1', '5.5.5.5')
    assert_equal(2, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['default'].size)
    dvl3 = create_routerospfarea_default_virtual_link('Wolfpack', 'default',
                                                      '6.6.6.6', '5.5.5.5')
    assert_equal(3, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['default'].size)
    vvl1 = create_routerospfarea_vrf_virtual_link
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['blue'].size)
    vvl2 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'blue',
                                                  '1000', '5.5.5.5')
    assert_equal(2, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['blue'].size)
    vvl3 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'red',
                                                  '1000', '5.5.5.5')
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['red'].size)
    vvl4 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'red',
                                                  '2000', '5.5.5.5')
    assert_equal(2, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['red'].size)
    vvl5 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'red',
                                                  '2000', '2.2.2.2')
    assert_equal(3, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['red'].size)
    dvl1.destroy
    dvl2.destroy
    dvl3.destroy
    vvl1.destroy
    vvl2.destroy
    vvl3.destroy
    vvl4.destroy
    vvl5.destroy
    assert_empty(RouterOspfAreaVirtualLink.virtual_links)
  end
end
