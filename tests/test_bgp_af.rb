#!/usr/bin/env ruby
# RouterBgpAF Unit Tests
#
# Richard Wellum, August, 2015
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/bgp", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/bgp_af", __FILE__)

class TestRouterBgpAF < CiscoTestCase
  def setup
    super
    # Disable and enable feature bgp before each test to ensure we
    # are starting with a clean slate for each test.
    @device.cmd("configure terminal")
    @device.cmd("no feature bgp")
    @device.cmd("feature bgp")
    @device.cmd("end")
    node.cache_flush
  end

  def get_bgp_af_cfg(asn, vrf, af)
    afi, safi = af
    string =
      @device.cmd("show run bgp all | sec 'bgp #{asn}' |  sec 'vrf #{vrf}' | " +
                  "sec 'address-family #{afi} #{safi}' | no-more")
    string
  end

  ##
  ## BGP Address Family
  ## Validate that RouterBgp.afs is empty when bgp is not enabled
  ##
  def test_collection_empty
    node.cache_flush
    afs = RouterBgpAF.afs
    assert_empty(afs, "BGP address-family collection is not empty")
  end

  ##
  ## BGP Address Family
  ## Configure router bgp, some VRF's and address-family statements
  ## - verify that the final instance objects are correctly populated
  ##
  def test_collection_not_empty
    @device.cmd("configure terminal")
    @device.cmd("feature bgp")
    @device.cmd("router bgp 55")
    @device.cmd("address-family ipv4 unicast")
    @device.cmd("vrf red")
    @device.cmd("address-family ipv4 unicast")
    @device.cmd("vrf blue")
    @device.cmd("address-family ipv6 multicast")
    @device.cmd("vrf orange")
    @device.cmd("address-family ipv4 multicast")
    @device.cmd("vrf black")
    @device.cmd("address-family ipv6 unicast")
    @device.cmd("end")
    node.cache_flush

    # Construct a hash of routers, vrfs, afs
    routers = RouterBgpAF.afs
    refute_empty(routers, "Error: BGP address_family collection is empty")

    # Validate the collection
    routers.each do |asn, vrfs|
      assert((asn.kind_of? Fixnum),
             "Error: Autonomous number must be a fixed number")
      refute_empty(vrfs, "Error: Collection is empty")

      vrfs.each do |vrf, afs|
        refute_empty(afs, "Error: No Address Family found")
        assert(vrf.length > 0, "Error: No VRF found")
        afs.each do |af_key, af|
          afi = af_key[0]
          safi = af_key[1]
          assert(afi.length > 0, "Error: AFI length is zero")
          assert_match(/^ipv[46]/, afi, "Error: AFI must be ipv4 or ipv6")
          assert(safi.length > 0, "Error: SAFI length is zero")
        end
      end
    end
  end

  ########################################################
  #                      PROPERTIES                      #
  ########################################################

  ##
  ## default-information originate
  ##
  def test_set_get_default_information_originate
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.default_information_originate = true
    assert(bgp_af.default_information_originate,
           "Error: default-information originate not set")
    pattern = 'default-information originate'
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Expect it to match
    assert_match(pattern, af_string,
                 "Error: 'default_information originate' is not" +
                   " configured and should be")

    #
    # Unset and verify
    #

    # Do a 'no default-information originate'
    bgp_af.default_information_originate = false
    pattern = 'default-information originate'
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Expect it not to match
    refute_match(pattern, af_string,
                 "Error: 'default_information originate' " +
                   "is configured and should not be")
  end

  ##
  ## client-to-client reflection
  ##
  def test_set_get_client_to_client
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    bgp_af = RouterBgpAF.new(asn, vrf, af)
    pattern = 'client-to-client'

    #
    # Default is 'client-to-client' is configured
    #
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Expect it to match
    assert_match(pattern, af_string,
                 "Error: 'client-to-client' is not configured")
    #
    # Unset and verify
    #

    # Do a 'no client-to-client reflection'
    bgp_af.client_to_client = false
    pattern = 'no client-to-client'
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Fail if pattern IS NOT matched, expects it to match
    assert_match(pattern, af_string,
                 "Error: 'no client-to-client' is not configured and should be")

    #
    # Set and verify
    #

    # Do a 'client-to-client reflection'
    bgp_af.client_to_client = true
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Expect it not to match
    refute_match(pattern, af_string,
                 "Error: 'no client-to-client' is configured and should not be")
  end

  ##
  ## next_hop route-map
  ##
  def test_set_get_next_hop_route_map
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.next_hop_route_map = "drop_all"
    assert_match(bgp_af.next_hop_route_map, "drop_all",
                 "Error: nexthop route-map not set")
    pattern = 'nexthop route-map drop_all'
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Expect it to match
    assert_match(pattern, af_string,
                 "Error: 'nexthop route-map drop_all' is " +
                   "not configured and should be")

    #
    # Unset and verify
    #

    # Do a 'no nexthop route-map drop_all'
    bgp_af.next_hop_route_map = bgp_af.default_next_hop_route_map
    pattern = 'nexthop route-map drop_all'
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Expect it not to match
    refute_match(pattern, af_string,
                 "Error: 'nexthop route-map drop_all' is " +
                   "configured and should not be")
  end

  ##
  ## network
  ##
  def networks_delta_same(asn, vrf, af, il1, sl1, il2, sl2)
    /ipv4/.match(af) ? af = %w(ipv4 unicast) : af = %w(ipv6 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify 'is' and 'should' network list contain
    # items and are identical
    #
    il1.each { |network, rtmap|
      bgp_af.network_set(network, rtmap)
    }

    config_list = bgp_af.networks_delta(sl1)
    assert_empty(config_list[:add],
      "Error: config_list[:add] should be empty")
    assert_empty(config_list[:remove],
      "Error: config_list[:remove] should be empty")

    # Apply config_list
    bgp_af.networks = config_list

    # Verify is_list on device
    sl1.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }

    # Cleanup for next test section
    sl1.each { |network, rtmap|
      bgp_af.network_remove(network, rtmap)
    }
    assert_empty(bgp_af.networks,
      "Error: all networks should have been removed")

    #
    # Set and verify 'is' and 'should' network list contain
    # the same number of items but they differ.
    #
    il2.each { |network, rtmap|
      bgp_af.network_set(network, rtmap)
    }

    config_list = bgp_af.networks_delta(sl2)
    assert_equal(3, config_list[:add].size,
      "Error: config_list[:add] should contain 3 items")
    assert_equal(2, config_list[:remove].size,
      "Error: config_list[:remove] should contain 2 items")
    assert_includes(config_list[:add], sl2[0],
      "Error: config_list[:add] should contain #{sl2[0]}")
    assert_includes(config_list[:add], sl2[1],
      "Error: config_list[:add] should contain #{sl2[1]}")
    assert_includes(config_list[:add], sl2[3],
      "Error: config_list[:add] should contain #{sl2[3]}")
    assert_includes(config_list[:remove], il2[1],
      "Error: config_list[:remove] should contain #{il2[1]}")
    assert_includes(config_list[:remove], il2[3],
      "Error: config_list[:remove] should contain #{il2[3]}")

    # Apply config_list
    bgp_af.networks = config_list

    # Verify is_list on device
    sl2.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }
  end

  def test_networks_delta_same
    # Both is_list1(il1) and should_list1(sl1) are identical
    il1 = sl1 = [
      ['192.168.5.0/24', 'rtmap1'],
      ['192.168.6.0/24', 'rtmap2'],
      ['192.168.7.0/24', 'rtmap3'],
      ['192.168.9.0/24'],
    ]
    # Item 1, 2 and 4 differ between is_list2(il2) and should_list2(sl2)
    il2 = [
      ['192.168.5.0/24', 'rtmap1'],
      ['192.168.6.0/24', 'rtmap2'],
      ['192.168.7.0/24', 'rtmap3'],
      ['192.168.9.0/24'],
    ]
    sl2 = [
      ['192.168.5.0/24', 'rtmap8'],
      ['192.168.55.0/24'],
      ['192.168.7.0/24', 'rtmap3'],
      ['192.168.99.0/24'],
    ]
    # Test ipv4 unicast, vrf red, default and blue
    asn, vrf, af = '55', 'red', 'ipv4 unicast'
    networks_delta_same(asn, vrf, af, il1, sl1, il2, sl2)
    asn, vrf, af = '55', 'default', 'ipv4 unicast'
    networks_delta_same(asn, vrf, af, il1, sl1, il2, sl2)
    asn, vrf, af = '55', 'blue', 'ipv4 unicast'
    networks_delta_same(asn, vrf, af, il1, sl1, il2, sl2)

    # Both is_list1(il1) and should_list1(sl1) are identical
    il1 = sl1 = [
      ['2000:123:38::/64', 'rtmap1'],
      ['2000:123:39::/64', 'rtmap2'],
      ['2000:123:40::/64', 'rtmap3'],
      ['2000:123:41::/64'],
    ]
    # Item 1, 2 and 4 differ between is_list2(il2) and should_list2(sl2)
    il2 = [
      ['2000:123:38::/64', 'rtmap1'],
      ['2000:123:39::/64', 'rtmap2'],
      ['2000:123:40::/64', 'rtmap3'],
      ['2000:123:41::/64'],
    ]
    sl2 = [
      ['2000:123:38::/64', 'rtmap8'],
      ['2000:123:5::/64'],
      ['2000:123:40::/64', 'rtmap3'],
      ['2000:123:9::/64'],
    ]
    # Test ipv6 unicast, vrf red, default and blue
    asn, vrf, af = '55', 'default', 'ipv6 unicast'
    networks_delta_same(asn, vrf, af, il1, sl1, il2, sl2)
    asn, vrf, af = '55', 'red', 'ipv6 unicast'
    networks_delta_same(asn, vrf, af, il1, sl1, il2, sl2)
    asn, vrf, af = '55', 'green', 'ipv6 unicast'
    networks_delta_same(asn, vrf, af, il1, sl1, il2, sl2)
  end

  def networks_delta_is_greaterthan_should(asn, vrf, af, il, sl)
    /ipv4/.match(af) ? af = %w(ipv4 unicast) : af = %w(ipv6 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify 'is' network list contains more items then
    # the 'should' network list.
    #
    il.each { |network, rtmap|
      bgp_af.network_set(network, rtmap)
    }

    config_list = bgp_af.networks_delta(sl)
    assert_empty(config_list[:add],
      "Error: config_list[:add] should be empty")
    assert_equal(1, config_list[:remove].size,
      "Error: config_list[:remove] should contain one item")
    assert_equal(il[1], config_list[:remove][0],
      "Error: config_list[:remove] has the wrong network")

    # Apply config_list
    bgp_af.networks = config_list

    # Verify is_list on device
    sl.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }
  end

  def test_networks_delta_is_greaterthan_should
    # is_list(il) has an additional item 4
    il = [
      ['192.168.5.0/24', 'rtmap1'],
      ['192.168.6.0/24', 'rtmap2'],
      ['192.168.7.0/24', 'rtmap3'],
      ['192.168.9.0/24'],
    ]
    sl = [
      ['192.168.5.0/24', 'rtmap1'],
      ['192.168.7.0/24', 'rtmap3'],
      ['192.168.9.0/24'],
    ]
    # Test ipv4 unicast vrf red
    asn, vrf, af = '55', 'red', 'ipv4 unicast'
    networks_delta_is_greaterthan_should(asn, vrf, af, il, sl)

    # is_list(il) has an additional item 4
    il = [
      ['2000:123:38::/64', 'rtmap1'],
      ['2000:123:39::/64', 'rtmap2'],
      ['2000:123:40::/64', 'rtmap3'],
      ['2000:123:41::/64'],
    ]
    sl = [
      ['2000:123:38::/64', 'rtmap1'],
      ['2000:123:40::/64', 'rtmap3'],
      ['2000:123:41::/64'],
    ]
    # Test ipv6 unicast vrf red
    asn, vrf, af = '55', 'red', 'ipv6 unicast'
    networks_delta_is_greaterthan_should(asn, vrf, af, il, sl)
  end

  def networks_delta_is_lessthan_should(asn, vrf, af, il1, sl1, il2, sl2)
    /ipv4/.match(af) ? af = %w(ipv4 unicast) : af = %w(ipv6 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify 'is' network list contains less items then
    # the 'should' network list.
    #
    il1.each { |network, rtmap|
      bgp_af.network_set(network, rtmap)
    }

    config_list = bgp_af.networks_delta(sl1)
    assert_equal(1, config_list[:add].size,
      "Error: config_list[:add] should contain 1 item")
    assert_empty(config_list[:remove],
      "Error: config_list[:remove] should be empty")
    assert_equal(sl1[3], config_list[:add][0],
      "Error: config_list[:add] has the wrong network")

    # Apply config_list
    bgp_af.networks = config_list

    # Verify is_list on device
    sl1.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }

    # Cleanup for next test section
    sl1.each { |network, rtmap|
      bgp_af.network_remove(network, rtmap)
    }
    assert_empty(bgp_af.networks,
      "Error: all networks should have been removed")

    #
    # Set and verify 'is' network list contains less items then
    # the 'should' network list and some of the items are
    # different
    #
    il2.each { |network, rtmap|
      bgp_af.network_set(network, rtmap)
    }

    config_list = bgp_af.networks_delta(sl2)
    assert_equal(2, config_list[:add].size,
      "Error: config_list[:add] should contain 2 items")
    assert_equal(1, config_list[:remove].size,
      "Error: config_list[:remove] should contain 1 item")
    assert_includes(config_list[:add], sl2[0],
      "Error: config_list[:add] should contain #{sl2[0]}")
    assert_includes(config_list[:add], sl2[3],
      "Error: config_list[:add] should contain #{sl2[3]}")
    assert_includes(config_list[:remove], il2[0],
      "Error: config_list[:remove] should contain #{il2[0]}")

    # Apply config_list
    bgp_af.networks = config_list

    # Verify is_list on device
    sl2.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }
  end

  def test_networks_delta_is_lessthan_should
    # Lists are identical except for additional item 4 in
    # should list (sl1)
    il1 = [
      ['192.168.5.0/24', 'rtmap1'],
      ['192.168.6.0/24', 'rtmap2'],
      ['192.168.7.0/24', 'rtmap3']]
    sl1 = [
      ['192.168.5.0/24', 'rtmap1'],
      ['192.168.6.0/24', 'rtmap2'],
      ['192.168.7.0/24', 'rtmap3'],
      ['192.168.9.0/24'],
    ]
    # Item 1 in both lists are different
    # Additonal item 4 in should list (sl2)
    il2 = [
      ['192.168.5.0/24', 'rtmap1'],
      ['192.168.6.0/24', 'rtmap2'],
      ['192.168.7.0/24', 'rtmap3'],
    ]
    sl2 = [
      ['192.168.55.0/24', 'rtmap55'],
      ['192.168.6.0/24', 'rtmap2'],
      ['192.168.7.0/24', 'rtmap3'],
      ['192.168.9.0/24'],
    ]
    # Test ipv4 unicast vrf default
    asn, vrf, af = '55', 'default', 'ipv4 unicast'
    networks_delta_is_lessthan_should(asn, vrf, af, il1, sl1, il2, sl2)

    # Lists are identical except for additional item 4 in
    # should list (sl1)
    il1 = [
      ['2000:123:38::/64', 'rtmap1'],
      ['2000:123:39::/64', 'rtmap2'],
      ['2000:123:40::/64', 'rtmap3']]
    sl1 = [
      ['2000:123:38::/64', 'rtmap1'],
      ['2000:123:39::/64', 'rtmap2'],
      ['2000:123:40::/64', 'rtmap3'],
      ['2000:123:41::/64'],
    ]
    # Item 1 in both lists are different
    # Additonal item 4 in should list (sl2)
    il2 = [
      ['2000:123:38::/64', 'rtmap1'],
      ['2000:123:39::/64', 'rtmap2'],
      ['2000:123:40::/64', 'rtmap3'],
    ]
    sl2 = [
      ['2000:155:55::/64', 'rtmap1'],
      ['2000:123:39::/64', 'rtmap2'],
      ['2000:123:40::/64', 'rtmap3'],
      ['2000:123:41::/64'],
    ]
    # Test ipv6 unicast vrf default
    asn, vrf, af = '55', 'default', 'ipv6 unicast'
    networks_delta_is_lessthan_should(asn, vrf, af, il1, sl1, il2, sl2)
  end

  def test_networks_scale
    asn = '55'
    vrf = 'blue'
    af = %w(ipv4 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Configure 50 networks and then add and remove from the list
    #
    should_list = []
    (1..50).each { |x|
      bgp_af.network_set("192.168.#{x}.5/24", "rtmap#{x}")
      should_list.push ["192.168.#{x}.0/24", "rtmap#{x}"]
    }

    config_list = bgp_af.networks_delta(should_list)
    assert_empty(config_list[:add],
      "Error: config_list[:add] should be empty")
    assert_empty(config_list[:remove],
      "Error: config_list[:remove] should be empty")

    # Apply config_list
    bgp_af.networks = config_list

    # Verify is_list on device
    should_list.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }

    # Change the second half of the list to new values
    (25..50).each { |x|
      should_list[x] = ["10.168.#{x}.0/24", "rtmap#{x}"]
    }

    # Add new values with route maps
    (51..80).each { |x|
      should_list[x] = ["10.55.#{x}.0/24", "rtmap#{x}"]
    }

    # Add new values without route maps
    (81..90).each { |x|
      should_list[x] = ["10.55.#{x}.0/24"]
    }

    # Apply config_list
    bgp_af.networks = bgp_af.networks_delta(should_list)

    # Verify is_list on device
    should_list.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }

    # Cleanup
    should_list.each { |network, rtmap|
      bgp_af.network_remove(network, rtmap)
    }
    assert_empty(bgp_af.networks,
      "Error: all networks should have been removed")
  end

  def test_networks_routemap_change
    asn = '55'
    vrf = 'blue'
    af = %w(ipv4 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    il = [['192.168.5.0/24', 'rtmap1']]
    sl = [['192.168.5.0/24', 'rtmap2']]

    bgp_af.network_set(il[0][0], il[0][1])

    config_list = bgp_af.networks_delta(sl)
    assert_equal(1, config_list[:add].size,
      "Error: config_list[:add] should contain 1 item")
    assert_empty(config_list[:remove],
      "Error: config_list[:remove] should be empty")
    assert_equal('rtmap2', config_list[:add][0][1],
      "Error: config_list[:add] routemap value should be 'rtmap2'")

    # Apply config_list
    bgp_af.networks = config_list

    # Verify should_list on device
    sl.each { |network|
      assert_includes(bgp_af.networks, network,
        "Error: device should contain network #{network}")
    }
  end
end
