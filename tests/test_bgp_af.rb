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
  def test_bgp_address_family_collection_empty
    node.cache_flush
    afs = RouterBgpAF.afs
    assert_empty(afs, "BGP address-family collection is not empty")
  end

  ##
  ## BGP Address Family
  ## Configure router bgp, some VRF's and address-family statements
  ## - verify that the final instance objects are correctly populated
  ##
  def test_bgp_address_family_collection_not_empty
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
  def test_routerbgp_set_get_default_information_originate
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
  def test_routerbgp_set_get_client_to_client
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
  ## nexthop route-map
  ##
  def test_routerbgp_set_get_nexthop_route_map
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.nexthop_route_map = "drop_all"
    assert_match(bgp_af.nexthop_route_map, "drop_all",
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
    bgp_af.nexthop_route_map = bgp_af.default_nexthop_route_map
    pattern = 'nexthop route-map drop_all'
    af_string = get_bgp_af_cfg(asn, vrf, af)

    # Expect it not to match
    refute_match(pattern, af_string,
                 "Error: 'nexthop route-map drop_all' is " +
                   "configured and should not be")
  end
end
