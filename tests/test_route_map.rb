# Copyright (c) 2017 Cisco and/or its affiliates.
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

def evergreen_or_later?
  return false if Utils.image_version?(/7.0.3.I2|I3|I4/)
  true
end

def dplus_n9k?
  return true if Utils.image_version?(/7.0.3.I4/) &&
                 node.product_id[/N9K/]
  false
end

# TestRouteMap - Minitest for RouteMap
# node utility class
class TestRouteMap < CiscoTestCase
  @skip_unless_supported = 'route_map'

  def setup
    super
  end

  def teardown
    RouteMap.maps.each do |_rmname, sequences|
      sequences.each do |_sequence, actions|
        actions.each do |_action, obj|
          obj.destroy
        end
      end
    end
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
    create_route_map('my1', '100', 'permit')
    create_route_map('my1', '101', 'permit')
    create_route_map('my1', '102', 'deny')
    create_route_map('my2', '102', 'permit')
    create_route_map('my2', '104', 'deny')
    create_route_map('my3', '105', 'deny')
    assert_equal(1, RouteMap.maps['my1']['100'].size)
    assert_equal(1, RouteMap.maps['my1']['101'].size)
    assert_equal(1, RouteMap.maps['my1']['102'].size)
    assert_equal(3, RouteMap.maps['my1'].size)
    assert_equal(1, RouteMap.maps['my2']['102'].size)
    assert_equal(1, RouteMap.maps['my2']['104'].size)
    assert_equal(2, RouteMap.maps['my2'].size)
    assert_equal(1, RouteMap.maps['my3']['105'].size)
    assert_equal(1, RouteMap.maps['my3'].size)
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
    refute(rm.match_community_exact_match)
    rm.match_community_set(array, true)
    assert_equal(array, rm.match_community)
    assert(rm.match_community_exact_match)
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
    refute(rm.match_ext_community_exact_match)
    rm.match_ext_community_set(array, true)
    assert_equal(array, rm.match_ext_community)
    assert(rm.match_ext_community_exact_match)
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

  def test_match_ip_addr_access_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv4_addr_access_list, rm.match_ipv4_addr_access_list)
    assert_equal(rm.default_match_ipv6_addr_access_list, rm.match_ipv6_addr_access_list)
    rm.match_ip_addr_access_list('MyAccessList',
                                 rm.default_match_ipv6_addr_access_list)
    assert_equal('MyAccessList', rm.match_ipv4_addr_access_list)
    assert_equal(rm.default_match_ipv6_addr_access_list, rm.match_ipv6_addr_access_list)
    rm.match_ip_addr_access_list(rm.default_match_ipv4_addr_access_list,
                                 'MyV6AccessList')
    assert_equal(rm.default_match_ipv4_addr_access_list, rm.match_ipv4_addr_access_list)
    assert_equal('MyV6AccessList', rm.match_ipv6_addr_access_list)
    rm.match_ip_addr_access_list(rm.default_match_ipv4_addr_access_list,
                                 rm.default_match_ipv6_addr_access_list)
    assert_equal(rm.default_match_ipv4_addr_access_list, rm.match_ipv4_addr_access_list)
    assert_equal(rm.default_match_ipv6_addr_access_list, rm.match_ipv6_addr_access_list)
  end

  def test_match_ip_addr_prefix_list
    rm = create_route_map
    assert_equal(rm.default_match_ipv4_addr_prefix_list, rm.match_ipv4_addr_prefix_list)
    assert_equal(rm.default_match_ipv6_addr_prefix_list, rm.match_ipv6_addr_prefix_list)
    array1 = %w(pre1 pre7 pre5)
    array2 = rm.default_match_ipv6_addr_prefix_list
    rm.match_ip_addr_prefix_list(array1, array2)
    assert_equal(array1, rm.match_ipv4_addr_prefix_list)
    assert_equal(rm.default_match_ipv6_addr_prefix_list, rm.match_ipv6_addr_prefix_list)
    array1 = rm.default_match_ipv4_addr_prefix_list
    array2 = %w(pre1 pre7 pre5)
    rm.match_ip_addr_prefix_list(array1, array2)
    assert_equal(rm.default_match_ipv4_addr_prefix_list, rm.match_ipv4_addr_prefix_list)
    assert_equal(array2, rm.match_ipv6_addr_prefix_list)
    array2 = rm.default_match_ipv6_addr_prefix_list
    rm.match_ip_addr_prefix_list(array1, array2)
    assert_equal(rm.default_match_ipv4_addr_prefix_list, rm.match_ipv4_addr_prefix_list)
    assert_equal(rm.default_match_ipv6_addr_prefix_list, rm.match_ipv6_addr_prefix_list)
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
    assert(rm.match_ipv4_multicast_enable)
    assert_equal('242.1.1.1/32', rm.match_ipv4_multicast_src_addr)
    assert_equal('239.2.2.2/32', rm.match_ipv4_multicast_group_addr)
    assert_equal('242.1.1.1/32', rm.match_ipv4_multicast_rp_addr)
    assert_equal('ASM', rm.match_ipv4_multicast_rp_type)

    rm = match_ipv4_multicast_helper(match_ipv4_multicast_src_addr:               '242.1.1.1/32',
                                     match_ipv4_multicast_group_range_begin_addr: '239.1.1.1',
                                     match_ipv4_multicast_group_range_end_addr:   '239.2.2.2',
                                     match_ipv4_multicast_rp_addr:                '242.1.1.1/32',
                                     match_ipv4_multicast_rp_type:                'Bidir')
    assert(rm.match_ipv4_multicast_enable)
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
    assert(rm.match_ipv6_multicast_enable)
    assert_equal('2001::348:0:0/96', rm.match_ipv6_multicast_src_addr)
    assert_equal('ff0e::2:101:0:0/96', rm.match_ipv6_multicast_group_addr)
    assert_equal('2001::348:0:0/96', rm.match_ipv6_multicast_rp_addr)
    assert_equal('ASM', rm.match_ipv6_multicast_rp_type)

    rm = match_ipv6_multicast_helper(match_ipv6_multicast_src_addr:               '2001::348:0:0/96',
                                     match_ipv6_multicast_group_range_begin_addr: 'ff01::',
                                     match_ipv6_multicast_group_range_end_addr:   'ff02::',
                                     match_ipv6_multicast_rp_addr:                '2001::348:0:0/96',
                                     match_ipv6_multicast_rp_type:                'Bidir')
    assert(rm.match_ipv6_multicast_enable)
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
    # bug CSCvc82934 on n9k running dplus
    skip('platform not supported for this test') if dplus_n9k?
    skip_incompat_version?('route_map', 'match_metric')
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
    assert(rm.match_route_type_external)
    assert(rm.match_route_type_internal)
    assert(rm.match_route_type_level_1)
    assert(rm.match_route_type_local)
    assert(rm.match_route_type_type_2)
    refute(rm.match_route_type_type_1)
    refute(rm.match_route_type_inter_area)
    refute(rm.match_route_type_level_2)
    refute(rm.match_route_type_nssa_external)
    refute(rm.match_route_type_type_1)

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

    assert(rm.match_route_type_external)
    assert(rm.match_route_type_internal)
    assert(rm.match_route_type_level_1)
    assert(rm.match_route_type_local)
    assert(rm.match_route_type_type_2)
    assert(rm.match_route_type_type_1)
    assert(rm.match_route_type_inter_area)
    assert(rm.match_route_type_level_2)
    assert(rm.match_route_type_nssa_external)
    assert(rm.match_route_type_type_1)
    rm = match_route_type_helper(
      match_route_type_level_1:  true)
    assert(rm.match_route_type_level_1)
    rm = match_route_type_helper({})
    refute(rm.match_route_type_external)
    refute(rm.match_route_type_internal)
    refute(rm.match_route_type_level_1)
    refute(rm.match_route_type_local)
    refute(rm.match_route_type_type_2)
    refute(rm.match_route_type_type_1)
    refute(rm.match_route_type_inter_area)
    refute(rm.match_route_type_level_2)
    refute(rm.match_route_type_nssa_external)
    refute(rm.match_route_type_type_1)
  end

  def test_match_ospf_area
    rm = create_route_map
    if validate_property_excluded?('route_map', 'match_ospf_area')
      assert_nil(rm.match_ospf_area)
      assert_raises(Cisco::UnsupportedError) do
        rm.match_ospf_area = %w(10 7 222)
      end
      return
    end
    skip_incompat_version?('route_map', 'match_ospf_area')
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
    assert(rm.match_evpn_route_type_1)
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
    assert(rm.match_evpn_route_type_3)
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
    assert(rm.match_evpn_route_type_4)
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
    assert(rm.match_evpn_route_type_5)
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
    assert(rm.match_evpn_route_type_6)
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
    assert(rm.match_evpn_route_type_all)
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
    assert(rm.match_evpn_route_type_2_all)
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
    assert(rm.match_evpn_route_type_2_mac_ip)
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
    assert(rm.match_evpn_route_type_2_mac_only)
    rm.match_evpn_route_type_2_mac_only = rm.default_match_evpn_route_type_2_mac_only
    assert_equal(rm.default_match_evpn_route_type_2_mac_only, rm.match_evpn_route_type_2_mac_only)
  end

  def test_set_comm_list
    rm = create_route_map
    assert_equal(rm.default_set_comm_list, rm.set_comm_list)
    rm.set_comm_list = 'abc'
    assert_equal('abc', rm.set_comm_list)
    rm.set_comm_list = rm.default_set_comm_list
    assert_equal(rm.default_set_comm_list, rm.set_comm_list)
  end

  def test_set_extcomm_list
    rm = create_route_map
    assert_equal(rm.default_set_extcomm_list, rm.set_extcomm_list)
    rm.set_extcomm_list = 'xyz'
    assert_equal('xyz', rm.set_extcomm_list)
    rm.set_extcomm_list = rm.default_set_extcomm_list
    assert_equal(rm.default_set_extcomm_list, rm.set_extcomm_list)
  end

  def test_set_forwarding_addr
    rm = create_route_map
    assert_equal(rm.default_set_forwarding_addr, rm.set_forwarding_addr)
    rm.set_forwarding_addr = true
    assert(rm.set_forwarding_addr)
    rm.set_forwarding_addr = rm.default_set_forwarding_addr
    assert_equal(rm.default_set_forwarding_addr, rm.set_forwarding_addr)
  end

  def test_set_ipv4_next_hop_peer_addr
    rm = lset_ip_next_hop_helper(v4peer: true)
    assert(rm.set_ipv4_next_hop_peer_addr)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv4_next_hop_peer_addr,
                 rm.set_ipv4_next_hop_peer_addr)
  end

  def test_set_ipv4_next_hop_redist
    skip_incompat_version?('route_map', 'set_ipv4_next_hop_redist')
    rm = lset_ip_next_hop_helper(v4red: true)
    assert(rm.set_ipv4_next_hop_redist)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv4_next_hop_redist,
                 rm.set_ipv4_next_hop_redist)
  end

  def test_set_ipv4_next_hop_unchanged
    rm = lset_ip_next_hop_helper(v4unc: true)
    assert(rm.set_ipv4_next_hop_unchanged)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv4_next_hop_unchanged,
                 rm.set_ipv4_next_hop_unchanged)
  end

  def test_set_level
    rm = create_route_map
    assert_equal(rm.default_set_level, rm.set_level)
    rm.set_level = 'level-1'
    assert_equal('level-1', rm.set_level)
    rm.set_level = 'level-1-2'
    assert_equal('level-1-2', rm.set_level)
    rm.set_level = 'level-2'
    assert_equal('level-2', rm.set_level)
    rm.set_level = rm.default_set_level
    assert_equal(rm.default_set_level, rm.set_level)
  end

  def test_set_local_preference
    rm = create_route_map
    assert_equal(rm.default_set_local_preference, rm.set_local_preference)
    rm.set_local_preference = 100
    assert_equal(100, rm.set_local_preference)
    rm.set_local_preference = rm.default_set_local_preference
    assert_equal(rm.default_set_local_preference, rm.set_local_preference)
  end

  def test_set_metric_type
    rm = create_route_map
    assert_equal(rm.default_set_metric_type, rm.set_metric_type)
    rm.set_metric_type = 'external'
    assert_equal('external', rm.set_metric_type)
    rm.set_metric_type = 'internal'
    assert_equal('internal', rm.set_metric_type)
    rm.set_metric_type = 'type-1'
    assert_equal('type-1', rm.set_metric_type)
    rm.set_metric_type = 'type-2'
    assert_equal('type-2', rm.set_metric_type)
    rm.set_metric_type = rm.default_set_metric_type
    assert_equal(rm.default_set_metric_type, rm.set_metric_type)
  end

  def test_set_nssa_only
    rm = create_route_map
    assert_equal(rm.default_set_nssa_only, rm.set_nssa_only)
    rm.set_nssa_only = true
    assert(rm.set_nssa_only)
    rm.set_nssa_only = rm.default_set_nssa_only
    assert_equal(rm.default_set_nssa_only, rm.set_nssa_only)
  end

  def test_set_origin
    rm = create_route_map
    assert_equal(rm.default_set_origin, rm.set_origin)
    rm.set_origin = 'egp'
    assert_equal('egp', rm.set_origin)
    rm.set_origin = 'incomplete'
    assert_equal('incomplete', rm.set_origin)
    rm.set_origin = 'igp'
    assert_equal('igp', rm.set_origin)
    rm.set_origin = rm.default_set_origin
    assert_equal(rm.default_set_origin, rm.set_origin)
  end

  def test_set_path_selection
    rm = create_route_map
    assert_equal(rm.default_set_path_selection, rm.set_path_selection)
    rm.set_path_selection = true
    assert(rm.set_path_selection)
    rm.set_path_selection = rm.default_set_path_selection
    assert_equal(rm.default_set_path_selection, rm.set_path_selection)
  end

  def test_set_tag
    rm = create_route_map
    assert_equal(rm.default_set_tag, rm.set_tag)
    rm.set_tag = 100
    assert_equal(100, rm.set_tag)
    rm.set_tag = rm.default_set_tag
    assert_equal(rm.default_set_tag, rm.set_tag)
  end

  def test_set_vrf
    rm = create_route_map
    if validate_property_excluded?('route_map', 'set_vrf')
      assert_nil(rm.set_vrf)
      assert_raises(Cisco::UnsupportedError) do
        rm.set_vrf = 'default'
      end
      return
    end
    assert_equal(rm.default_set_vrf, rm.set_vrf)
    rm.set_vrf = 'default_vrf'
    assert_equal('default_vrf', rm.set_vrf)
    rm.set_vrf = 'management'
    assert_equal('management', rm.set_vrf)
    rm.set_vrf = 'igp'
    assert_equal('igp', rm.set_vrf)
    rm.set_vrf = rm.default_set_vrf
    assert_equal(rm.default_set_vrf, rm.set_vrf)
  end

  def test_set_weight
    rm = create_route_map
    assert_equal(rm.default_set_weight, rm.set_weight)
    rm.set_weight = 333
    assert_equal(333, rm.set_weight)
    rm.set_weight = rm.default_set_weight
    assert_equal(rm.default_set_weight, rm.set_weight)
  end

  def test_set_metric
    rm = create_route_map
    assert_equal(rm.default_set_metric_additive, rm.set_metric_additive)
    assert_equal(rm.default_set_metric_bandwidth, rm.set_metric_bandwidth)
    assert_equal(rm.default_set_metric_delay, rm.set_metric_delay)
    assert_equal(rm.default_set_metric_reliability,
                 rm.set_metric_reliability)
    assert_equal(rm.default_set_metric_effective_bandwidth,
                 rm.set_metric_effective_bandwidth)
    assert_equal(rm.default_set_metric_mtu, rm.set_metric_mtu)
    rm.set_metric_set(false, 44, 55, 66, 77, 88)
    refute(rm.set_metric_additive)
    assert_equal(44, rm.set_metric_bandwidth)
    assert_equal(55, rm.set_metric_delay)
    assert_equal(66, rm.set_metric_reliability)
    assert_equal(77, rm.set_metric_effective_bandwidth)
    assert_equal(88, rm.set_metric_mtu)
    rm.set_metric_set(true, 33, false, false, false, false)
    assert(rm.set_metric_additive)
    assert_equal(33, rm.set_metric_bandwidth)
    refute(rm.set_metric_delay)
    refute(rm.set_metric_reliability)
    refute(rm.set_metric_effective_bandwidth)
    refute(rm.set_metric_mtu)
    rm.set_metric_set(false, false, false, false, false, false)
    assert_equal(rm.default_set_metric_additive, rm.set_metric_additive)
    assert_equal(rm.default_set_metric_bandwidth, rm.set_metric_bandwidth)
    assert_equal(rm.default_set_metric_delay, rm.set_metric_delay)
    assert_equal(rm.default_set_metric_reliability,
                 rm.set_metric_reliability)
    assert_equal(rm.default_set_metric_effective_bandwidth,
                 rm.set_metric_effective_bandwidth)
    assert_equal(rm.default_set_metric_mtu, rm.set_metric_mtu)
  end

  def test_set_dampening
    rm = create_route_map
    assert_equal(rm.default_set_dampening_half_life,
                 rm.set_dampening_half_life)
    assert_equal(rm.default_set_dampening_reuse,
                 rm.set_dampening_reuse)
    assert_equal(rm.default_set_dampening_suppress,
                 rm.set_dampening_suppress)
    assert_equal(rm.default_set_dampening_max_duation,
                 rm.set_dampening_max_duation)
    rm.set_dampening_set(6, 22, 44, 55)
    assert_equal(6, rm.set_dampening_half_life)
    assert_equal(22, rm.set_dampening_reuse)
    assert_equal(44, rm.set_dampening_suppress)
    assert_equal(55, rm.set_dampening_max_duation)
    rm.set_dampening_set(false, false, false, false)
    assert_equal(rm.default_set_dampening_half_life,
                 rm.set_dampening_half_life)
    assert_equal(rm.default_set_dampening_reuse,
                 rm.set_dampening_reuse)
    assert_equal(rm.default_set_dampening_suppress,
                 rm.set_dampening_suppress)
    assert_equal(rm.default_set_dampening_max_duation,
                 rm.set_dampening_max_duation)
  end

  def test_set_distance
    rm = create_route_map
    assert_equal(rm.default_set_distance_igp_ebgp,
                 rm.set_distance_igp_ebgp)
    assert_equal(rm.default_set_distance_internal,
                 rm.set_distance_internal)
    assert_equal(rm.default_set_distance_local,
                 rm.set_distance_local)
    rm.set_distance_set(1, 2, 3)
    assert_equal(1, rm.set_distance_igp_ebgp)
    assert_equal(2, rm.set_distance_internal)
    assert_equal(3, rm.set_distance_local)
    rm.set_distance_set(1, false, false)
    assert_equal(1, rm.set_distance_igp_ebgp)
    refute(rm.set_distance_internal)
    refute(rm.set_distance_local)
    rm.set_distance_set(1, 2, false)
    assert_equal(1, rm.set_distance_igp_ebgp)
    assert_equal(2, rm.set_distance_internal)
    refute(rm.set_distance_local)
    rm.set_distance_set(false, false, false)
    assert_equal(rm.default_set_distance_igp_ebgp,
                 rm.set_distance_igp_ebgp)
    assert_equal(rm.default_set_distance_internal,
                 rm.set_distance_internal)
    assert_equal(rm.default_set_distance_local,
                 rm.set_distance_local)
  end

  def test_set_as_path_prepend_last_as
    rm = create_route_map
    assert_equal(rm.default_set_as_path_prepend_last_as,
                 rm.set_as_path_prepend_last_as)
    rm.set_as_path_prepend_last_as = 1
    assert_equal(1, rm.set_as_path_prepend_last_as)
    rm.set_as_path_prepend_last_as = rm.default_set_as_path_prepend_last_as
    assert_equal(rm.default_set_as_path_prepend_last_as,
                 rm.set_as_path_prepend_last_as)
  end

  def test_set_as_path_tag
    rm = create_route_map
    assert_equal(rm.default_set_as_path_tag,
                 rm.set_as_path_tag)
    rm.set_as_path_tag = true
    assert(rm.set_as_path_tag)
    rm.set_as_path_tag = rm.default_set_as_path_tag
    assert_equal(rm.default_set_as_path_tag,
                 rm.set_as_path_tag)
  end

  def test_set_as_path_prepend
    rm = create_route_map
    assert_equal(rm.default_set_as_path_prepend,
                 rm.set_as_path_prepend)
    arr = ['55.77', '12', '45.3', '4.77', '5']
    rm.set_as_path_prepend = arr
    assert_equal(arr, rm.set_as_path_prepend)
    rm.set_as_path_prepend = rm.default_set_as_path_prepend
    assert_equal(rm.default_set_as_path_prepend,
                 rm.set_as_path_prepend)
  end

  def test_set_interface
    rm = lset_ip_next_hop_helper(intf: 'Null0')
    assert_equal('Null0', rm.set_interface)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_interface,
                 rm.set_interface)
  end

  def test_set_ipv4_prefix
    rm = create_route_map
    if validate_property_excluded?('route_map', 'set_ipv4_prefix')
      assert_nil(rm.set_ipv4_prefix)
      assert_raises(Cisco::UnsupportedError) do
        rm.set_ipv4_prefix = 'abcdef'
      end
      return
    end
    assert_equal(rm.default_set_ipv4_prefix, rm.set_ipv4_prefix)
    rm.set_ipv4_prefix = 'abcdef'
    assert_equal('abcdef', rm.set_ipv4_prefix)
    rm.set_ipv4_prefix = rm.default_set_ipv4_prefix
    assert_equal(rm.default_set_ipv4_prefix, rm.set_ipv4_prefix)
  end

  def test_set_ip_precedence
    rm = create_route_map
    assert_equal(rm.default_set_ipv4_precedence, rm.set_ipv4_precedence)
    assert_equal(rm.default_set_ipv6_precedence, rm.set_ipv6_precedence)
    rm.set_ip_precedence('critical', rm.default_set_ipv6_precedence)
    assert_equal('critical', rm.set_ipv4_precedence)
    assert_equal(rm.default_set_ipv6_precedence, rm.set_ipv6_precedence)
    rm.set_ip_precedence(rm.default_set_ipv6_precedence, 'network')
    assert_equal(rm.default_set_ipv4_precedence, rm.set_ipv4_precedence)
    assert_equal('network', rm.set_ipv6_precedence)
    rm.set_ip_precedence(rm.default_set_ipv4_precedence,
                         rm.default_set_ipv6_precedence)
    assert_equal(rm.default_set_ipv4_precedence, rm.set_ipv4_precedence)
    assert_equal(rm.default_set_ipv6_precedence, rm.set_ipv6_precedence)
  end

  def test_set_ipv4_default_next_hop
    skip('platform not supported for this test') if node.product_id[/(N5|N6|N9|N9.*-F)/]
    arr = %w(1.1.1.1 2.2.2.2 3.3.3.3)
    rm = lset_ip_next_hop_helper(v4dnh: arr)
    assert_equal(arr, rm.set_ipv4_default_next_hop)
    assert_equal(rm.default_set_ipv4_default_next_hop_load_share,
                 rm.set_ipv4_default_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v4dnh: arr, v4dls: true)
    assert_equal(arr, rm.set_ipv4_default_next_hop)
    assert(rm.set_ipv4_default_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v4dls: true)
    assert_equal(rm.default_set_ipv4_default_next_hop,
                 rm.set_ipv4_default_next_hop)
    assert(rm.set_ipv4_default_next_hop_load_share)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv4_default_next_hop,
                 rm.set_ipv4_default_next_hop)
    assert_equal(rm.default_set_ipv4_default_next_hop_load_share,
                 rm.set_ipv4_default_next_hop_load_share)
  end

  def test_set_ipv4_next_hop
    arr = %w(1.1.1.1 2.2.2.2 3.3.3.3)
    rm = lset_ip_next_hop_helper(v4nh: arr)
    assert_equal(arr, rm.set_ipv4_next_hop)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv4_next_hop,
                 rm.set_ipv4_next_hop)
  end

  def test_set_ipv4_next_hop_load_share
    # bug on fretta
    skip('platform not supported for this test') if node.product_id[/(N5|N6)/]
    skip_incompat_version?('route_map', 'set_ipv4_next_hop_load_share')
    arr = %w(1.1.1.1 2.2.2.2 3.3.3.3)
    rm = lset_ip_next_hop_helper(v4nh: arr)
    assert_equal(arr, rm.set_ipv4_next_hop)
    assert_equal(rm.default_set_ipv4_next_hop_load_share,
                 rm.set_ipv4_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v4nh: arr, v4ls: true)
    assert_equal(arr, rm.set_ipv4_next_hop)
    assert(rm.set_ipv4_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v4ls: true)
    assert_equal(rm.default_set_ipv4_next_hop,
                 rm.set_ipv4_next_hop)
    assert(rm.set_ipv4_next_hop_load_share)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv4_next_hop,
                 rm.set_ipv4_next_hop)
    assert_equal(rm.default_set_ipv4_next_hop_load_share,
                 rm.set_ipv4_next_hop_load_share)
  end

  def test_set_ipv6_next_hop_peer_addr
    rm = lset_ip_next_hop_helper(v6peer: true)
    assert(rm.set_ipv6_next_hop_peer_addr)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv6_next_hop_peer_addr,
                 rm.set_ipv6_next_hop_peer_addr)
  end

  def test_set_ipv6_next_hop_redist
    skip_incompat_version?('route_map', 'set_ipv6_next_hop_redist')
    rm = lset_ip_next_hop_helper(v6red: true)
    assert(rm.set_ipv6_next_hop_redist)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv6_next_hop_redist,
                 rm.set_ipv6_next_hop_redist)
  end

  def test_set_ipv6_next_hop_unchanged
    rm = lset_ip_next_hop_helper(v6unc: true)
    assert(rm.set_ipv6_next_hop_unchanged)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv6_next_hop_unchanged,
                 rm.set_ipv6_next_hop_unchanged)
  end

  def test_set_ipv6_prefix
    rm = create_route_map
    if validate_property_excluded?('route_map', 'set_ipv6_prefix')
      assert_nil(rm.set_ipv6_prefix)
      assert_raises(Cisco::UnsupportedError) do
        rm.set_ipv6_prefix = 'abcdef'
      end
      return
    end
    assert_equal(rm.default_set_ipv6_prefix, rm.set_ipv6_prefix)
    rm.set_ipv6_prefix = 'abcdef'
    assert_equal('abcdef', rm.set_ipv6_prefix)
    rm.set_ipv6_prefix = rm.default_set_ipv6_prefix
    assert_equal(rm.default_set_ipv6_prefix, rm.set_ipv6_prefix)
  end

  def test_set_ipv6_default_next_hop
    skip('platform not supported for this test') if node.product_id[/(N5|N6|N9|N9.*-F)/]
    arr = %w(2000::1 2000::11 2000::22)
    rm = lset_ip_next_hop_helper(v6dnh: arr)
    assert_equal(arr, rm.set_ipv6_default_next_hop)
    assert_equal(rm.default_set_ipv6_default_next_hop_load_share,
                 rm.set_ipv6_default_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v6dnh: arr, v6dls: true)
    assert_equal(arr, rm.set_ipv6_default_next_hop)
    assert(rm.set_ipv6_default_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v6dls: true)
    assert_equal(rm.default_set_ipv6_default_next_hop,
                 rm.set_ipv6_default_next_hop)
    assert(rm.set_ipv6_default_next_hop_load_share)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv6_default_next_hop,
                 rm.set_ipv6_default_next_hop)
    assert_equal(rm.default_set_ipv6_default_next_hop_load_share,
                 rm.set_ipv6_default_next_hop_load_share)
  end

  def test_set_ipv6_next_hop
    arr = %w(2000::1 2000::11 2000::22)
    rm = lset_ip_next_hop_helper(v6nh: arr)
    assert_equal(arr, rm.set_ipv6_next_hop)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv6_next_hop,
                 rm.set_ipv6_next_hop)
  end

  def test_set_ipv6_next_hop_load_share
    # bug on fretta
    skip('platform not supported for this test') if node.product_id[/(N5|N6)/]
    skip_incompat_version?('route_map', 'set_ipv6_next_hop_load_share')
    arr = %w(2000::1 2000::11 2000::22)
    rm = lset_ip_next_hop_helper(v6nh: arr)
    assert_equal(arr, rm.set_ipv6_next_hop)
    assert_equal(rm.default_set_ipv6_next_hop_load_share,
                 rm.set_ipv6_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v6nh: arr, v6ls: true)
    assert_equal(arr, rm.set_ipv6_next_hop)
    assert(rm.set_ipv6_next_hop_load_share)
    rm = lset_ip_next_hop_helper(v6ls: true)
    assert_equal(rm.default_set_ipv6_next_hop,
                 rm.set_ipv6_next_hop)
    assert(rm.set_ipv6_next_hop_load_share)
    hash = {}
    rm = lset_ip_next_hop_helper(hash)
    assert_equal(rm.default_set_ipv6_next_hop,
                 rm.set_ipv6_next_hop)
    assert_equal(rm.default_set_ipv6_next_hop_load_share,
                 rm.set_ipv6_next_hop_load_share)
  end

  def test_set_community_no_asn
    # bug on n5/6k
    skip('platform not supported for this test') if node.product_id[/(N5|N6)/]
    skip_incompat_version?('route_map', 'set_community')
    rm = create_route_map
    assert_equal(rm.default_set_community_additive,
                 rm.set_community_additive)
    assert_equal(rm.default_set_community_asn,
                 rm.set_community_asn)
    assert_equal(rm.default_set_community_internet,
                 rm.set_community_internet)
    assert_equal(rm.default_set_community_local_as,
                 rm.set_community_local_as)
    assert_equal(rm.default_set_community_no_advtertise,
                 rm.set_community_no_advtertise)
    assert_equal(rm.default_set_community_no_export,
                 rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
    asn = rm.default_set_community_asn
    none = true
    noadv = false
    noexp = false
    add = false
    local = false
    inter = false
    rm.set_community_set(none, noadv, noexp, add, local, inter, asn)
    assert_equal(rm.default_set_community_additive,
                 rm.set_community_additive)
    assert_equal(rm.default_set_community_asn,
                 rm.set_community_asn)
    assert_equal(rm.default_set_community_internet,
                 rm.set_community_internet)
    assert_equal(rm.default_set_community_local_as,
                 rm.set_community_local_as)
    assert_equal(rm.default_set_community_no_advtertise,
                 rm.set_community_no_advtertise)
    assert_equal(rm.default_set_community_no_export,
                 rm.set_community_no_export)
    assert_equal(none, rm.set_community_none)
    none = false
    add = true
    rm.set_community_set(none, noadv, noexp, add, local, inter, asn)
    assert(rm.set_community_additive)
    assert_equal(rm.default_set_community_asn,
                 rm.set_community_asn)
    assert_equal(rm.default_set_community_internet,
                 rm.set_community_internet)
    assert_equal(rm.default_set_community_local_as,
                 rm.set_community_local_as)
    assert_equal(rm.default_set_community_no_advtertise,
                 rm.set_community_no_advtertise)
    assert_equal(rm.default_set_community_no_export,
                 rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
    noadv = true
    rm.set_community_set(none, noadv, noexp, add, local, inter, asn)
    assert(rm.set_community_additive)
    assert_equal(rm.default_set_community_asn,
                 rm.set_community_asn)
    assert_equal(rm.default_set_community_internet,
                 rm.set_community_internet)
    assert_equal(rm.default_set_community_local_as,
                 rm.set_community_local_as)
    assert(rm.set_community_no_advtertise)
    assert_equal(rm.default_set_community_no_export,
                 rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
    noadv = true
    noexp = true
    add = true
    local = true
    inter = true
    rm.set_community_set(none, noadv, noexp, add, local, inter, asn)
    assert(rm.set_community_additive)
    assert_equal(rm.default_set_community_asn,
                 rm.set_community_asn)
    assert(rm.set_community_internet)
    assert(rm.set_community_local_as)
    assert(rm.set_community_no_advtertise)
    assert(rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
    rm.set_community_set(false, false, false, false, false, false, asn)
    assert_equal(rm.default_set_community_additive,
                 rm.set_community_additive)
    assert_equal(rm.default_set_community_asn, rm.set_community_asn)
    assert_equal(rm.default_set_community_internet,
                 rm.set_community_internet)
    assert_equal(rm.default_set_community_local_as,
                 rm.set_community_local_as)
    assert_equal(rm.default_set_community_no_advtertise,
                 rm.set_community_no_advtertise)
    assert_equal(rm.default_set_community_no_export,
                 rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
  end

  def test_set_community_asn
    skip_incompat_version?('route_map', 'set_community')
    rm = create_route_map
    none = false
    noadv = true
    noexp = true
    add = true
    local = true
    inter = true
    asn = ['11:22', '33:44', '123:11']
    rm.set_community_set(none, noadv, noexp, add, local, inter, asn)
    assert(rm.set_community_additive)
    assert_equal(asn, rm.set_community_asn)
    assert(rm.set_community_internet)
    assert(rm.set_community_local_as)
    assert(rm.set_community_no_advtertise)
    assert(rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
    none = false
    noadv = false
    noexp = false
    add = false
    local = false
    inter = false
    rm.set_community_set(none, noadv, noexp, add, local, inter, asn)
    assert_equal(rm.default_set_community_additive,
                 rm.set_community_additive)
    assert_equal(asn, rm.set_community_asn)
    assert_equal(rm.default_set_community_internet,
                 rm.set_community_internet)
    assert_equal(rm.default_set_community_local_as,
                 rm.set_community_local_as)
    assert_equal(rm.default_set_community_no_advtertise,
                 rm.set_community_no_advtertise)
    assert_equal(rm.default_set_community_no_export,
                 rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
    asn = rm.default_set_community_asn
    rm.set_community_set(false, false, false, false, false, false, asn)
    assert_equal(rm.default_set_community_additive,
                 rm.set_community_additive)
    assert_equal(rm.default_set_community_asn, rm.set_community_asn)
    assert_equal(rm.default_set_community_internet,
                 rm.set_community_internet)
    assert_equal(rm.default_set_community_local_as,
                 rm.set_community_local_as)
    assert_equal(rm.default_set_community_no_advtertise,
                 rm.set_community_no_advtertise)
    assert_equal(rm.default_set_community_no_export,
                 rm.set_community_no_export)
    assert_equal(rm.default_set_community_none,
                 rm.set_community_none)
  end

  def test_extcommunity_4bytes
    skip_incompat_version?('route_map', 'set_extcommunity_4bytes')
    rm = create_route_map
    assert_equal(rm.default_set_extcommunity_4bytes_transitive,
                 rm.set_extcommunity_4bytes_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_non_transitive,
                 rm.set_extcommunity_4bytes_non_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_none,
                 rm.set_extcommunity_4bytes_none)
    assert_equal(rm.default_set_extcommunity_4bytes_additive,
                 rm.set_extcommunity_4bytes_additive)
    none = true
    tr = ntr = []
    add = false
    rm.set_extcommunity_4bytes_set(none, tr, ntr, add)
    assert(rm.set_extcommunity_4bytes_none)
    assert_equal(rm.default_set_extcommunity_4bytes_transitive,
                 rm.set_extcommunity_4bytes_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_non_transitive,
                 rm.set_extcommunity_4bytes_non_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_additive,
                 rm.set_extcommunity_4bytes_additive)
    none = false
    add = true
    rm.set_extcommunity_4bytes_set(none, tr, ntr, add)
    assert(rm.set_extcommunity_4bytes_additive)
    assert_equal(rm.default_set_extcommunity_4bytes_transitive,
                 rm.set_extcommunity_4bytes_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_non_transitive,
                 rm.set_extcommunity_4bytes_non_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_none,
                 rm.set_extcommunity_4bytes_none)
    tr = ['11:22', '33:44', '66:77']
    rm.set_extcommunity_4bytes_set(none, tr, ntr, add)
    assert(rm.set_extcommunity_4bytes_additive)
    assert_equal(tr, rm.set_extcommunity_4bytes_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_non_transitive,
                 rm.set_extcommunity_4bytes_non_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_none,
                 rm.set_extcommunity_4bytes_none)
    ntr = ['21:42', '43:22', '59:17']
    rm.set_extcommunity_4bytes_set(none, tr, ntr, add)
    assert(rm.set_extcommunity_4bytes_additive)
    assert_equal(tr, rm.set_extcommunity_4bytes_transitive)
    assert_equal(ntr, rm.set_extcommunity_4bytes_non_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_none,
                 rm.set_extcommunity_4bytes_none)
    add = false
    tr = ntr = []
    rm.set_extcommunity_4bytes_set(none, tr, ntr, add)
    assert_equal(rm.default_set_extcommunity_4bytes_transitive,
                 rm.set_extcommunity_4bytes_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_non_transitive,
                 rm.set_extcommunity_4bytes_non_transitive)
    assert_equal(rm.default_set_extcommunity_4bytes_none,
                 rm.set_extcommunity_4bytes_none)
    assert_equal(rm.default_set_extcommunity_4bytes_additive,
                 rm.set_extcommunity_4bytes_additive)
  end

  def test_extcommunity_rt
    # bug CSCvc92395 on fretta and n9k
    skip('platform not supported for this test') if node.product_id[/N9/]
    rm = create_route_map
    assert_equal(rm.default_set_extcommunity_rt_additive,
                 rm.set_extcommunity_rt_additive)
    assert_equal(rm.default_set_extcommunity_rt_asn,
                 rm.set_extcommunity_rt_asn)
    asn = []
    add = true
    rm.set_extcommunity_rt_set(asn, add)
    assert(rm.set_extcommunity_rt_additive)
    assert_equal(rm.default_set_extcommunity_rt_asn,
                 rm.set_extcommunity_rt_asn)
    asn = ['11:22', '33:44', '12.22.22.22:12', '123.256:543']
    rm.set_extcommunity_rt_set(asn, add)
    assert(rm.set_extcommunity_rt_additive)
    assert_equal(asn, rm.set_extcommunity_rt_asn)
    add = false
    rm.set_extcommunity_rt_set(asn, add)
    assert_equal(rm.default_set_extcommunity_rt_additive,
                 rm.set_extcommunity_rt_additive)
    assert_equal(asn, rm.set_extcommunity_rt_asn)
    asn = []
    rm.set_extcommunity_rt_set(asn, add)
    assert_equal(rm.default_set_extcommunity_rt_additive,
                 rm.set_extcommunity_rt_additive)
    assert_equal(rm.default_set_extcommunity_rt_asn,
                 rm.set_extcommunity_rt_asn)
  end

  def test_extcommunity_cost
    rm = create_route_map
    assert_equal(rm.default_set_extcommunity_cost_igp,
                 rm.set_extcommunity_cost_igp)
    assert_equal(rm.default_set_extcommunity_cost_pre_bestpath,
                 rm.set_extcommunity_cost_pre_bestpath)
    igp = [%w(0 23), %w(3 33), %w(100 10954)]
    pre = []
    rm.set_extcommunity_cost_set(igp, pre)
    assert_equal(igp, rm.set_extcommunity_cost_igp)
    assert_equal(rm.default_set_extcommunity_cost_pre_bestpath,
                 rm.set_extcommunity_cost_pre_bestpath)
    pre = [%w(23 999), %w(88 482), %w(120 2323)]
    rm.set_extcommunity_cost_set(igp, pre)
    assert_equal(igp, rm.set_extcommunity_cost_igp)
    assert_equal(pre, rm.set_extcommunity_cost_pre_bestpath)
    igp = []
    rm.set_extcommunity_cost_set(igp, pre)
    assert_equal(rm.default_set_extcommunity_cost_igp,
                 rm.set_extcommunity_cost_igp)
    assert_equal(pre, rm.set_extcommunity_cost_pre_bestpath)
    pre = []
    rm.set_extcommunity_cost_set(igp, pre)
    assert_equal(rm.default_set_extcommunity_cost_igp,
                 rm.set_extcommunity_cost_igp)
    assert_equal(rm.default_set_extcommunity_cost_pre_bestpath,
                 rm.set_extcommunity_cost_pre_bestpath)
  end

  def test_set_ip_next_hop_defaults
    rm = create_route_map
    assert_equal(rm.default_set_interface, rm.set_interface)
    assert_equal(rm.default_set_ipv4_default_next_hop,
                 rm.set_ipv4_default_next_hop) unless
      rm.default_set_ipv4_default_next_hop.nil?
    assert_equal(rm.default_set_ipv4_default_next_hop_load_share,
                 rm.set_ipv4_default_next_hop_load_share) unless
      rm.default_set_ipv4_default_next_hop_load_share.nil?
    assert_equal(rm.default_set_ipv4_next_hop,
                 rm.set_ipv4_next_hop) unless
      rm.default_set_ipv4_next_hop.nil?
    assert_equal(rm.default_set_ipv4_next_hop_load_share,
                 rm.set_ipv4_next_hop_load_share) unless
      rm.default_set_ipv4_next_hop_load_share.nil?
    assert_equal(rm.default_set_ipv4_next_hop_peer_addr,
                 rm.set_ipv4_next_hop_peer_addr)
    assert_equal(rm.default_set_ipv4_next_hop_redist,
                 rm.set_ipv4_next_hop_redist)
    assert_equal(rm.default_set_ipv4_next_hop_unchanged,
                 rm.set_ipv4_next_hop_unchanged)
    assert_equal(rm.default_set_ipv6_default_next_hop,
                 rm.set_ipv6_default_next_hop) unless
      rm.default_set_ipv6_default_next_hop.nil?
    assert_equal(rm.default_set_ipv6_default_next_hop_load_share,
                 rm.set_ipv6_default_next_hop_load_share) unless
      rm.default_set_ipv6_default_next_hop_load_share.nil?
    assert_equal(rm.default_set_ipv6_next_hop,
                 rm.set_ipv6_next_hop) unless
      rm.default_set_ipv6_next_hop.nil?
    assert_equal(rm.default_set_ipv6_next_hop_load_share,
                 rm.set_ipv6_next_hop_load_share) unless
      rm.default_set_ipv6_next_hop_load_share.nil?
    assert_equal(rm.default_set_ipv6_next_hop_peer_addr,
                 rm.set_ipv6_next_hop_peer_addr)
    assert_equal(rm.default_set_ipv6_next_hop_redist,
                 rm.set_ipv6_next_hop_redist)
    assert_equal(rm.default_set_ipv6_next_hop_unchanged,
                 rm.set_ipv6_next_hop_unchanged)
  end

  def lset_ip_next_hop_helper(props)
    rm = create_route_map
    if evergreen_or_later?
      attrs = {
        intf:   rm.default_set_interface,
        v4nh:   rm.default_set_ipv4_next_hop,
        v4ls:   rm.default_set_ipv4_next_hop_load_share,
        v4dnh:  rm.default_set_ipv4_default_next_hop,
        v4dls:  rm.default_set_ipv4_default_next_hop_load_share,
        v4peer: rm.default_set_ipv4_next_hop_peer_addr,
        v4red:  rm.default_set_ipv4_next_hop_redist,
        v4unc:  rm.default_set_ipv4_next_hop_unchanged,
        v6nh:   rm.default_set_ipv6_next_hop,
        v6ls:   rm.default_set_ipv6_next_hop_load_share,
        v6dnh:  rm.default_set_ipv6_default_next_hop,
        v6dls:  rm.default_set_ipv6_default_next_hop_load_share,
        v6peer: rm.default_set_ipv6_next_hop_peer_addr,
        v6red:  rm.default_set_ipv6_next_hop_redist,
        v6unc:  rm.default_set_ipv6_next_hop_unchanged,
      }.merge!(props)
    else
      attrs = {
        intf:   rm.default_set_interface,
        v4nh:   rm.default_set_ipv4_next_hop,
        v4ls:   rm.default_set_ipv4_next_hop_load_share,
        v4dnh:  rm.default_set_ipv4_default_next_hop,
        v4dls:  rm.default_set_ipv4_default_next_hop_load_share,
        v4peer: rm.default_set_ipv4_next_hop_peer_addr,
        v4unc:  rm.default_set_ipv4_next_hop_unchanged,
        v6nh:   rm.default_set_ipv6_next_hop,
        v6ls:   rm.default_set_ipv6_next_hop_load_share,
        v6dnh:  rm.default_set_ipv6_default_next_hop,
        v6dls:  rm.default_set_ipv6_default_next_hop_load_share,
        v6peer: rm.default_set_ipv6_next_hop_peer_addr,
        v6unc:  rm.default_set_ipv6_next_hop_unchanged,
      }.merge!(props)
    end
    rm.set_ip_next_hop_set(attrs)
    rm
  end
end
