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
require_relative '../lib/cisco_node_utils/route_map'

def newer_image_version?
  return false if Utils.image_version?(/7.0.3.I2|I3|I4/) ||
                  node.product_id[/(N5|N6|N7|N9.*-F)/]
  true
end

# TestRouteMap - Minitest for RouteMap
# node utility class
class TestRouteMap < CiscoTestCase
  @skip_unless_supported = 'route_map'

  def setup
    super
  end

  def teardown
    config_no_warn('no route-map MyRouteMap permit 100')
    super
  end

  def create_route_map(name='MyRouteMap', seq='100', action='permit')
    RouteMap.new(name, seq, action)
  end

  def test_description
    rm = create_route_map
    assert_equal(rm.default_description, rm.description)
    rm.description = 'TestRouteMap'
    assert_equal('TestRouteMap', rm.description)
    rm.description = rm.default_description
    assert_equal(rm.default_description, rm.description)
  end

  def test_collection_size
    rm1 = create_route_map('my1', '100', 'permit')
    rm2 = create_route_map('my1', '101', 'permit')
    rm3 = create_route_map('my1', '102', 'deny')
    rm4 = create_route_map('my2', '102', 'permit')
    rm5 = create_route_map('my2', '104', 'deny')
    rm6 = create_route_map('my3', '105', 'deny')
    assert_equal(1, RouteMap.maps['my1']['100'].size)
    assert_equal(1, RouteMap.maps['my1']['101'].size)
    assert_equal(1, RouteMap.maps['my1']['102'].size)
    assert_equal(3, RouteMap.maps['my1'].size)
    assert_equal(1, RouteMap.maps['my2']['102'].size)
    assert_equal(1, RouteMap.maps['my2']['104'].size)
    assert_equal(2, RouteMap.maps['my2'].size)
    assert_equal(1, RouteMap.maps['my3']['105'].size)
    assert_equal(1, RouteMap.maps['my3'].size)
    rm1.destroy
    rm2.destroy
    rm3.destroy
    rm4.destroy
    rm5.destroy
    rm6.destroy
  end

  def test_match_as_number
    rm = create_route_map
    assert_equal(rm.default_match_as_number, rm.match_as_number)
    array = ['3', '22-34', '35', '100', '101-220']
    rm.match_as_number = array
    assert_equal(array, rm.match_as_number)
    rm.match_as_number = rm.default_match_as_number
    assert_equal(rm.default_match_as_number, rm.match_as_number)
  end

  def test_match_as_number_as_path_list
    rm = create_route_map
    assert_equal(rm.default_match_as_number_as_path_list, rm.match_as_number_as_path_list)
    array = %w(cbc xyz pwd)
    rm.match_as_number_as_path_list = array
    assert_equal(array, rm.match_as_number_as_path_list)
    rm.match_as_number_as_path_list = rm.default_match_as_number_as_path_list
    assert_equal(rm.default_match_as_number_as_path_list, rm.match_as_number_as_path_list)
  end

  def test_community
    rm = create_route_map
    assert_equal(rm.default_match_community, rm.match_community)
    assert_equal(rm.default_match_community_exact_match, rm.match_community_exact_match)
    array = %w(public private)
    rm.match_community_set(array, false)
    assert_equal(array, rm.match_community)
    assert_equal(false, rm.match_community_exact_match)
    rm.match_community_set(array, true)
    assert_equal(array, rm.match_community)
    assert_equal(true, rm.match_community_exact_match)
    rm.match_community_set(rm.default_match_community, rm.default_match_community_exact_match)
    assert_equal(rm.default_match_community, rm.match_community)
    assert_equal(rm.default_match_community_exact_match, rm.match_community_exact_match)
  end

  def test_match_ext_community
    rm = create_route_map
    assert_equal(rm.default_match_ext_community, rm.match_ext_community)
    assert_equal(rm.default_match_ext_community_exact_match, rm.match_ext_community_exact_match)
    array = %w(public private)
    rm.match_ext_community_set(array, false)
    assert_equal(array, rm.match_ext_community)
    assert_equal(false, rm.match_ext_community_exact_match)
    rm.match_ext_community_set(array, true)
    assert_equal(array, rm.match_ext_community)
    assert_equal(true, rm.match_ext_community_exact_match)
    rm.match_ext_community_set(rm.default_match_ext_community, rm.default_match_ext_community_exact_match)
    assert_equal(rm.default_match_ext_community, rm.match_ext_community)
    assert_equal(rm.default_match_ext_community_exact_match, rm.match_ext_community_exact_match)
  end

  def test_match_interface
    rm = create_route_map
    assert_equal(rm.default_match_interface, rm.match_interface)
    array = %w(ethernet1/1 loopback2 mgmt0 null0 port-channel10)
    rm.match_interface = array
    assert_equal(array, rm.match_interface)
    rm.match_interface = rm.default_match_interface
    assert_equal(rm.default_match_interface, rm.match_interface)
  end

  def test_match_tag
    rm = create_route_map
    assert_equal(rm.default_match_tag, rm.match_tag)
    array = %w(5 342 28 3221)
    rm.match_tag = array
    assert_equal(array, rm.match_tag)
    rm.match_tag = rm.default_match_tag
    assert_equal(rm.default_match_tag, rm.match_tag)
  end

  def test_match_src_proto
    rm = create_route_map
    assert_equal(rm.default_match_src_proto, rm.match_src_proto)
    array = %w(tcp udp igmp)
    rm.match_src_proto = array
    assert_equal(array, rm.match_src_proto)
    rm.match_src_proto = rm.default_match_src_proto
    assert_equal(rm.default_match_src_proto, rm.match_src_proto)
  end

  def test_match_ipv4_addr_access_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv4_addr_access_list, rm.match_ipv4_addr_access_list)
    rm.match_ipv4_addr_access_list = 'MyAccessList'
    assert_equal('MyAccessList', rm.match_ipv4_addr_access_list)
    rm.match_ipv4_addr_access_list = rm.default_match_ipv4_addr_access_list
    assert_equal(rm.default_match_ipv4_addr_access_list, rm.match_ipv4_addr_access_list)
  end

  def test_match_ipv4_addr_prefix_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv4_addr_prefix_list, rm.match_ipv4_addr_prefix_list)
    array = %w(pre1 pre7 pre5)
    rm.match_ipv4_addr_prefix_list = array
    assert_equal(array, rm.match_ipv4_addr_prefix_list)
    rm.match_ipv4_addr_prefix_list = rm.default_match_ipv4_addr_prefix_list
    assert_equal(rm.default_match_ipv4_addr_prefix_list, rm.match_ipv4_addr_prefix_list)
  end

  def test_match_ipv4_next_hop_prefix_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv4_next_hop_prefix_list, rm.match_ipv4_next_hop_prefix_list)
    array = %w(nh5 nh1 nh42)
    rm.match_ipv4_next_hop_prefix_list = array
    assert_equal(array, rm.match_ipv4_next_hop_prefix_list)
    rm.match_ipv4_next_hop_prefix_list = rm.default_match_ipv4_next_hop_prefix_list
    assert_equal(rm.default_match_ipv4_next_hop_prefix_list, rm.match_ipv4_next_hop_prefix_list)
  end

  def test_match_ipv4_route_src_prefix_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv4_route_src_prefix_list, rm.match_ipv4_route_src_prefix_list)
    array = %w(rs1 rs22 pre15)
    rm.match_ipv4_route_src_prefix_list = array
    assert_equal(array, rm.match_ipv4_route_src_prefix_list)
    rm.match_ipv4_route_src_prefix_list = rm.default_match_ipv4_route_src_prefix_list
    assert_equal(rm.default_match_ipv4_route_src_prefix_list, rm.match_ipv4_route_src_prefix_list)
  end

  def match_ipv4_multicast_helper(props)
    rm = create_route_map
    test_hash = {
      match_ipv4_multicast_enable:                 true,
      match_ipv4_multicast_src_addr:               rm.default_match_ipv4_multicast_src_addr,
      match_ipv4_multicast_group_addr:             rm.default_match_ipv4_multicast_group_addr,
      match_ipv4_multicast_group_range_begin_addr: rm.default_match_ipv4_multicast_group_range_begin_addr,
      match_ipv4_multicast_group_range_end_addr:   rm.default_match_ipv4_multicast_group_range_end_addr,
      match_ipv4_multicast_rp_addr:                rm.default_match_ipv4_multicast_rp_addr,
      match_ipv4_multicast_rp_type:                rm.default_match_ipv4_multicast_rp_type,
    }.merge!(props)
    rm.match_ipv4_multicast_set(test_hash)
    rm
  end

  def test_match_ipv4_multicast
    rm = match_ipv4_multicast_helper(match_ipv4_multicast_src_addr:   '242.1.1.1/32',
                                     match_ipv4_multicast_group_addr: '239.2.2.2/32',
                                     match_ipv4_multicast_rp_addr:    '242.1.1.1/32',
                                     match_ipv4_multicast_rp_type:    'ASM')
    assert_equal(true, rm.match_ipv4_multicast_enable)
    assert_equal('242.1.1.1/32', rm.match_ipv4_multicast_src_addr)
    assert_equal('239.2.2.2/32', rm.match_ipv4_multicast_group_addr)
    assert_equal('242.1.1.1/32', rm.match_ipv4_multicast_rp_addr)
    assert_equal('ASM', rm.match_ipv4_multicast_rp_type)

    rm = match_ipv4_multicast_helper(match_ipv4_multicast_src_addr:               '242.1.1.1/32',
                                     match_ipv4_multicast_group_range_begin_addr: '239.1.1.1',
                                     match_ipv4_multicast_group_range_end_addr:   '239.2.2.2',
                                     match_ipv4_multicast_rp_addr:                '242.1.1.1/32',
                                     match_ipv4_multicast_rp_type:                'Bidir')
    assert_equal(true, rm.match_ipv4_multicast_enable)
    assert_equal('242.1.1.1/32', rm.match_ipv4_multicast_src_addr)
    assert_equal('239.1.1.1', rm.match_ipv4_multicast_group_range_begin_addr)
    assert_equal('239.2.2.2', rm.match_ipv4_multicast_group_range_end_addr)
    assert_equal('242.1.1.1/32', rm.match_ipv4_multicast_rp_addr)
    assert_equal('Bidir', rm.match_ipv4_multicast_rp_type)

    rm = match_ipv4_multicast_helper(match_ipv4_multicast_enable: false)
    assert_equal(rm.default_match_ipv4_multicast_enable, rm.match_ipv4_multicast_enable)
    assert_equal(rm.default_match_ipv4_multicast_src_addr, rm.match_ipv4_multicast_src_addr)
    assert_equal(rm.default_match_ipv4_multicast_group_addr, rm.match_ipv4_multicast_group_addr)
    assert_equal(rm.default_match_ipv4_multicast_group_range_begin_addr, rm.match_ipv4_multicast_group_range_begin_addr)
    assert_equal(rm.default_match_ipv4_multicast_group_range_end_addr, rm.match_ipv4_multicast_group_range_end_addr)
    assert_equal(rm.default_match_ipv4_multicast_rp_addr, rm.match_ipv4_multicast_rp_addr)
    assert_equal(rm.default_match_ipv4_multicast_rp_type, rm.match_ipv4_multicast_rp_type)
  end

  def test_match_ipv6_addr_access_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv6_addr_access_list, rm.match_ipv6_addr_access_list)
    rm.match_ipv6_addr_access_list = 'MyAccessList'
    assert_equal('MyAccessList', rm.match_ipv6_addr_access_list)
    rm.match_ipv6_addr_access_list = rm.default_match_ipv6_addr_access_list
    assert_equal(rm.default_match_ipv6_addr_access_list, rm.match_ipv6_addr_access_list)
  end

  def test_match_ipv6_addr_prefix_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv6_addr_prefix_list, rm.match_ipv6_addr_prefix_list)
    array = %w(pre1 pre7 pre5)
    rm.match_ipv6_addr_prefix_list = array
    assert_equal(array, rm.match_ipv6_addr_prefix_list)
    rm.match_ipv6_addr_prefix_list = rm.default_match_ipv6_addr_prefix_list
    assert_equal(rm.default_match_ipv6_addr_prefix_list, rm.match_ipv6_addr_prefix_list)
  end

  def test_match_ipv6_next_hop_prefix_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv6_next_hop_prefix_list, rm.match_ipv6_next_hop_prefix_list)
    array = %w(nh5 nh1 nh42)
    rm.match_ipv6_next_hop_prefix_list = array
    assert_equal(array, rm.match_ipv6_next_hop_prefix_list)
    rm.match_ipv6_next_hop_prefix_list = rm.default_match_ipv6_next_hop_prefix_list
    assert_equal(rm.default_match_ipv6_next_hop_prefix_list, rm.match_ipv6_next_hop_prefix_list)
  end

  def test_match_ipv6_route_src_prefix_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv6_route_src_prefix_list, rm.match_ipv6_route_src_prefix_list)
    array = %w(rs1 rs22 pre15)
    rm.match_ipv6_route_src_prefix_list = array
    assert_equal(array, rm.match_ipv6_route_src_prefix_list)
    rm.match_ipv6_route_src_prefix_list = rm.default_match_ipv6_route_src_prefix_list
    assert_equal(rm.default_match_ipv6_route_src_prefix_list, rm.match_ipv6_route_src_prefix_list)
  end

  def match_ipv6_multicast_helper(props)
    rm = create_route_map
    test_hash = {
      match_ipv6_multicast_enable:                 true,
      match_ipv6_multicast_src_addr:               rm.default_match_ipv6_multicast_src_addr,
      match_ipv6_multicast_group_addr:             rm.default_match_ipv6_multicast_group_addr,
      match_ipv6_multicast_group_range_begin_addr: rm.default_match_ipv6_multicast_group_range_begin_addr,
      match_ipv6_multicast_group_range_end_addr:   rm.default_match_ipv6_multicast_group_range_end_addr,
      match_ipv6_multicast_rp_addr:                rm.default_match_ipv6_multicast_rp_addr,
      match_ipv6_multicast_rp_type:                rm.default_match_ipv6_multicast_rp_type,
    }.merge!(props)
    rm.match_ipv6_multicast_set(test_hash)
    rm
  end

  def test_match_ipv6_multicast
    rm = match_ipv6_multicast_helper(match_ipv6_multicast_src_addr:   '2001::348:0:0/96',
                                     match_ipv6_multicast_group_addr: 'ff0e::2:101:0:0/96',
                                     match_ipv6_multicast_rp_addr:    '2001::348:0:0/96',
                                     match_ipv6_multicast_rp_type:    'ASM')
    assert_equal(true, rm.match_ipv6_multicast_enable)
    assert_equal('2001::348:0:0/96', rm.match_ipv6_multicast_src_addr)
    assert_equal('ff0e::2:101:0:0/96', rm.match_ipv6_multicast_group_addr)
    assert_equal('2001::348:0:0/96', rm.match_ipv6_multicast_rp_addr)
    assert_equal('ASM', rm.match_ipv6_multicast_rp_type)

    rm = match_ipv6_multicast_helper(match_ipv6_multicast_src_addr:               '2001::348:0:0/96',
                                     match_ipv6_multicast_group_range_begin_addr: 'ff01::',
                                     match_ipv6_multicast_group_range_end_addr:   'ff02::',
                                     match_ipv6_multicast_rp_addr:                '2001::348:0:0/96',
                                     match_ipv6_multicast_rp_type:                'Bidir')
    assert_equal(true, rm.match_ipv6_multicast_enable)
    assert_equal('2001::348:0:0/96', rm.match_ipv6_multicast_src_addr)
    assert_equal('ff01::', rm.match_ipv6_multicast_group_range_begin_addr)
    assert_equal('ff02::', rm.match_ipv6_multicast_group_range_end_addr)
    assert_equal('2001::348:0:0/96', rm.match_ipv6_multicast_rp_addr)
    assert_equal('Bidir', rm.match_ipv6_multicast_rp_type)

    rm = match_ipv6_multicast_helper(match_ipv6_multicast_enable: false)
    assert_equal(rm.default_match_ipv6_multicast_enable, rm.match_ipv6_multicast_enable)
    assert_equal(rm.default_match_ipv6_multicast_src_addr, rm.match_ipv6_multicast_src_addr)
    assert_equal(rm.default_match_ipv6_multicast_group_addr, rm.match_ipv6_multicast_group_addr)
    assert_equal(rm.default_match_ipv6_multicast_group_range_begin_addr, rm.match_ipv6_multicast_group_range_begin_addr)
    assert_equal(rm.default_match_ipv6_multicast_group_range_end_addr, rm.match_ipv6_multicast_group_range_end_addr)
    assert_equal(rm.default_match_ipv6_multicast_rp_addr, rm.match_ipv6_multicast_rp_addr)
    assert_equal(rm.default_match_ipv6_multicast_rp_type, rm.match_ipv6_multicast_rp_type)
  end

  def test_match_metric
    rm = create_route_map
    assert_equal(rm.default_match_metric, rm.match_metric)
    metric = [%w(1 0), %w(8 0), %w(224 9), %w(23 0), %w(5 8), %w(6 0)]
    rm.match_metric = metric
    assert_equal(metric, rm.match_metric)
    metric = [%w(22 5), %w(5 0), %w(24 9), %w(238 255)]
    rm.match_metric = metric
    assert_equal(metric, rm.match_metric)
    rm.match_metric = rm.default_match_metric
    assert_equal(rm.default_match_metric, rm.match_metric)
  end

  def match_route_type_helper(props)
    rm = create_route_map
    test_hash = {
      match_route_type_external:      rm.default_match_route_type_external,
      match_route_type_inter_area:    rm.default_match_route_type_inter_area,
      match_route_type_internal:      rm.default_match_route_type_internal,
      match_route_type_intra_area:    rm.default_match_route_type_intra_area,
      match_route_type_level_1:       rm.default_match_route_type_level_1,
      match_route_type_level_2:       rm.default_match_route_type_level_2,
      match_route_type_local:         rm.default_match_route_type_local,
      match_route_type_nssa_external: rm.default_match_route_type_nssa_external,
      match_route_type_type_1:        rm.default_match_route_type_type_1,
      match_route_type_type_2:        rm.default_match_route_type_type_2,
    }.merge!(props)
    rm.match_route_type_set(test_hash)
    rm
  end

  def test_match_route_type
    rm = match_route_type_helper(
      match_route_type_external: true,
      match_route_type_internal: true,
      match_route_type_level_1:  true,
      match_route_type_local:    true,
      match_route_type_type_2:   true)
    assert_equal(true, rm.match_route_type_external)
    assert_equal(true, rm.match_route_type_internal)
    assert_equal(true, rm.match_route_type_level_1)
    assert_equal(true, rm.match_route_type_local)
    assert_equal(true, rm.match_route_type_type_2)
    assert_equal(false, rm.match_route_type_type_1)
    assert_equal(false, rm.match_route_type_inter_area)
    assert_equal(false, rm.match_route_type_level_2)
    assert_equal(false, rm.match_route_type_nssa_external)
    assert_equal(false, rm.match_route_type_type_1)

    rm = match_route_type_helper(
      match_route_type_external:      true,
      match_route_type_inter_area:    true,
      match_route_type_internal:      true,
      match_route_type_intra_area:    true,
      match_route_type_level_1:       true,
      match_route_type_level_2:       true,
      match_route_type_local:         true,
      match_route_type_nssa_external: true,
      match_route_type_type_1:        true,
      match_route_type_type_2:        true)

    assert_equal(true, rm.match_route_type_external)
    assert_equal(true, rm.match_route_type_internal)
    assert_equal(true, rm.match_route_type_level_1)
    assert_equal(true, rm.match_route_type_local)
    assert_equal(true, rm.match_route_type_type_2)
    assert_equal(true, rm.match_route_type_type_1)
    assert_equal(true, rm.match_route_type_inter_area)
    assert_equal(true, rm.match_route_type_level_2)
    assert_equal(true, rm.match_route_type_nssa_external)
    assert_equal(true, rm.match_route_type_type_1)
    rm = match_route_type_helper(
      match_route_type_level_1:  true)
    assert_equal(true, rm.match_route_type_level_1)
    rm = match_route_type_helper({})
    assert_equal(false, rm.match_route_type_external)
    assert_equal(false, rm.match_route_type_internal)
    assert_equal(false, rm.match_route_type_level_1)
    assert_equal(false, rm.match_route_type_local)
    assert_equal(false, rm.match_route_type_type_2)
    assert_equal(false, rm.match_route_type_type_1)
    assert_equal(false, rm.match_route_type_inter_area)
    assert_equal(false, rm.match_route_type_level_2)
    assert_equal(false, rm.match_route_type_nssa_external)
    assert_equal(false, rm.match_route_type_type_1)
  end

  def test_match_ospf_area
    skip('platform not supported for this test') unless newer_image_version?
    rm = create_route_map
    assert_equal(rm.default_match_ospf_area, rm.match_ospf_area)
    array = %w(10 7 222)
    rm.match_ospf_area = array
    assert_equal(array, rm.match_ospf_area)
    rm.match_ospf_area = rm.default_match_ospf_area
    assert_equal(rm.default_match_ospf_area, rm.match_ospf_area)
  end

  def test_match_mac_list
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_mac_list')
      assert_nil(rm.match_mac_list)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_mac_list = %w(mac1 listmac some)
      end
      return
    end
    assert_equal(rm.default_match_mac_list, rm.match_mac_list)
    array = %w(mac1 listmac some)
    rm.match_mac_list = array
    assert_equal(array, rm.match_mac_list)
    rm.match_mac_list = rm.default_match_mac_list
    assert_equal(rm.default_match_mac_list, rm.match_mac_list)
  end

  def test_match_length
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_length')
      assert_nil(rm.match_length)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_length = %w(45 500)
      end
      return
    end
    assert_equal(rm.default_match_length, rm.match_length)
    array = %w(45 500)
    rm.match_length = array
    assert_equal(array, rm.match_length)
    rm.match_length = rm.default_match_length
    assert_equal(rm.default_match_length, rm.match_length)
  end

  def test_match_vlan
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_vlan')
      assert_nil(rm.match_vlan)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_vlan = '32, 45-200, 300-399, 402'
      end
      return
    end
    assert_equal(rm.default_match_vlan, rm.match_vlan)
    rm.match_vlan = '32, 45-200, 300-399, 402'
    assert_equal('32, 45-200, 300-399, 402', rm.match_vlan)
    rm.match_vlan = rm.default_match_vlan
    assert_equal(rm.default_match_vlan, rm.match_vlan)
  end

  def test_match_evpn_route_type1
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_1')
      assert_nil(rm.match_evpn_route_type_1)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_1 = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_1, rm.match_evpn_route_type_1)
    rm.match_evpn_route_type_1 = true
    assert_equal(true, rm.match_evpn_route_type_1)
    rm.match_evpn_route_type_1 = rm.default_match_evpn_route_type_1
    assert_equal(rm.default_match_evpn_route_type_1, rm.match_evpn_route_type_1)
  end

  def test_match_evpn_route_type3
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_3')
      assert_nil(rm.match_evpn_route_type_3)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_3 = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_3, rm.match_evpn_route_type_3)
    rm.match_evpn_route_type_3 = true
    assert_equal(true, rm.match_evpn_route_type_3)
    rm.match_evpn_route_type_3 = rm.default_match_evpn_route_type_3
    assert_equal(rm.default_match_evpn_route_type_3, rm.match_evpn_route_type_3)
  end

  def test_match_evpn_route_type4
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_4')
      assert_nil(rm.match_evpn_route_type_4)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_4 = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_4, rm.match_evpn_route_type_4)
    rm.match_evpn_route_type_4 = true
    assert_equal(true, rm.match_evpn_route_type_4)
    rm.match_evpn_route_type_4 = rm.default_match_evpn_route_type_4
    assert_equal(rm.default_match_evpn_route_type_4, rm.match_evpn_route_type_4)
  end

  def test_match_evpn_route_type5
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_5')
      assert_nil(rm.match_evpn_route_type_5)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_5 = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_5, rm.match_evpn_route_type_5)
    rm.match_evpn_route_type_5 = true
    assert_equal(true, rm.match_evpn_route_type_5)
    rm.match_evpn_route_type_5 = rm.default_match_evpn_route_type_5
    assert_equal(rm.default_match_evpn_route_type_5, rm.match_evpn_route_type_5)
  end

  def test_match_evpn_route_type6
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_6')
      assert_nil(rm.match_evpn_route_type_6)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_6 = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_6, rm.match_evpn_route_type_6)
    rm.match_evpn_route_type_6 = true
    assert_equal(true, rm.match_evpn_route_type_6)
    rm.match_evpn_route_type_6 = rm.default_match_evpn_route_type_6
    assert_equal(rm.default_match_evpn_route_type_6, rm.match_evpn_route_type_6)
  end

  def test_match_evpn_route_type_all
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_all')
      assert_nil(rm.match_evpn_route_type_all)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_all = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_all, rm.match_evpn_route_type_all)
    rm.match_evpn_route_type_all = true
    assert_equal(true, rm.match_evpn_route_type_all)
    rm.match_evpn_route_type_all = rm.default_match_evpn_route_type_all
    assert_equal(rm.default_match_evpn_route_type_all, rm.match_evpn_route_type_all)
  end

  def test_match_evpn_route_type_2_all
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_2_all')
      assert_nil(rm.match_evpn_route_type_2_all)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_2_all = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_2_all, rm.match_evpn_route_type_2_all)
    rm.match_evpn_route_type_2_all = true
    assert_equal(true, rm.match_evpn_route_type_2_all)
    rm.match_evpn_route_type_2_all = rm.default_match_evpn_route_type_2_all
    assert_equal(rm.default_match_evpn_route_type_2_all, rm.match_evpn_route_type_2_all)
  end

  def test_match_evpn_route_type_2_mac_ip
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_2_mac_ip')
      assert_nil(rm.match_evpn_route_type_2_mac_ip)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_2_mac_ip = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_2_mac_ip, rm.match_evpn_route_type_2_mac_ip)
    rm.match_evpn_route_type_2_mac_ip = true
    assert_equal(true, rm.match_evpn_route_type_2_mac_ip)
    rm.match_evpn_route_type_2_mac_ip = rm.default_match_evpn_route_type_2_mac_ip
    assert_equal(rm.default_match_evpn_route_type_2_mac_ip, rm.match_evpn_route_type_2_mac_ip)
  end

  def test_match_evpn_route_type_2_mac_only
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_evpn_route_type_2_mac_only')
      assert_nil(rm.match_evpn_route_type_2_mac_only)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_evpn_route_type_2_mac_only = true
      end
      return
    end
    assert_equal(rm.default_match_evpn_route_type_2_mac_only, rm.match_evpn_route_type_2_mac_only)
    rm.match_evpn_route_type_2_mac_only = true
    assert_equal(true, rm.match_evpn_route_type_2_mac_only)
    rm.match_evpn_route_type_2_mac_only = rm.default_match_evpn_route_type_2_mac_only
    assert_equal(rm.default_match_evpn_route_type_2_mac_only, rm.match_evpn_route_type_2_mac_only)
  end
end
