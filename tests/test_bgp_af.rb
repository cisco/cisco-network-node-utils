#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# RouterBgpAF Unit Tests
#
# Richard Wellum, August, 2015
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/bgp'
require_relative '../lib/cisco_node_utils/bgp_af'
require_relative '../lib/cisco_node_utils/feature'

# TestBgpAF - Minitest for RouterBgpAF class
class TestBgpAF < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_bgps if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    super
    remove_all_bgps
  end

  def get_bgp_af_cfg(asn, vrf, af)
    afi, safi = af
    string =
      @device.cmd("show run bgp all | sec 'bgp #{asn}' |  sec 'vrf #{vrf}' | " \
                  "sec 'address-family #{afi} #{safi}' | no-more")
    string
  end

  # show bgp ipv4 unicast dampening parameters
  # Route Flap Dampening Parameters for VRF default Address family IPv4 Unicast:
  # Default values in use:
  # Half-life time                 : 15 mins
  # Suppress penalty               : 2000
  # Reuse penalty                  : 750
  # Max suppress time              : 45 mins
  # Max suppress penalty           : 6000
  def get_bgp_af_dampening_params(_asn, vrf, af)
    afi = af.first
    safi = af.last
    @device.cmd("show bgp vrf #{vrf} #{afi} #{safi} dampening parameters")
  end

  ##
  ## BGP Address Family
  ## Validate that RouterBgp.afs is empty when bgp is not enabled
  ##
  def test_collection_empty
    node.cache_flush
    afs = RouterBgpAF.afs
    assert_empty(afs, 'BGP address-family collection is not empty')
  end

  ##
  ## BGP Address Family
  ## Configure router bgp, some VRF's and address-family statements
  ## - verify that the final instance objects are correctly populated
  ## Enable VXLAN and the EVPN
  ##
  def test_collection_not_empty
    config('feature bgp',
           'router bgp 55',
           'address-family ipv4 unicast',
           'vrf red',
           'address-family ipv4 unicast',
           'vrf blue',
           'address-family ipv6 multicast',
           'vrf orange',
           'address-family ipv4 multicast',
           'vrf black',
           'address-family ipv6 unicast')

    # Construct a hash of routers, vrfs, afs
    routers = RouterBgpAF.afs
    refute_empty(routers, 'Error: BGP address_family collection is empty')

    # Validate the collection
    routers.each do |asn, vrfs|
      assert((asn.kind_of? Fixnum),
             'Error: Autonomous number must be a fixed number')
      refute_empty(vrfs, 'Error: Collection is empty')

      vrfs.each do |vrf, afs|
        refute_empty(afs, 'Error: No Address Family found')
        assert(vrf.length > 0, 'Error: No VRF found')
        afs.each_key do |af_key|
          afi = af_key[0]
          safi = af_key[1]
          assert(afi.length > 0, 'Error: AFI length is zero')
          assert_match(/^ipv[46]/, afi, 'Error: AFI must be ipv4 or ipv6')
          assert(safi.length > 0, 'Error: SAFI length is zero')
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
  def test_default_information_originate
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.default_information_originate = true
    assert(bgp_af.default_information_originate,
           'Error: default-information originate not set')

    pattern = /^ *default-information originate$/
    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'default_information originate' is not" \
                   ' configured and should be')

    #
    # Unset and verify
    #

    # Do a 'no default-information originate'
    bgp_af.default_information_originate = false

    pattern = /^ *default-information originate$/
    af_string = get_bgp_af_cfg(asn, vrf, af)

    refute_match(pattern, af_string,
                 "Error: 'default_information originate' " \
                   'is configured and should not be')
  end

  ##
  ## client-to-client reflection
  ##
  def test_client_to_client
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    bgp_af = RouterBgpAF.new(asn, vrf, af)
    #
    # Default is 'client-to-client' is configured
    #
    assert(bgp_af.client_to_client,
           "Error: 'client-to-client is not configured but should be")
    #
    # Unset and verify
    #

    # Do a 'no client-to-client reflection'
    bgp_af.client_to_client = false
    pattern = /^ *no client-to-client reflection$/
    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'no client-to-client' is not configured and should be")

    #
    # Set and verify
    #

    # Do a 'client-to-client reflection'
    bgp_af.client_to_client = true
    af_string = get_bgp_af_cfg(asn, vrf, af)

    refute_match(pattern, af_string,
                 "Error: 'no client-to-client' is configured and should not be")
  end

  ##
  ## next_hop route-map
  ##
  def test_next_hop_route_map
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.next_hop_route_map = 'drop_all'
    assert_match(bgp_af.next_hop_route_map, 'drop_all',
                 'Error: nexthop route-map not set')
    pattern = /^ *nexthop route-map drop_all$/
    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'nexthop route-map drop_all' is " \
                   'not configured and should be')

    #
    # Unset and verify
    #

    # Do a 'no nexthop route-map drop_all'
    bgp_af.next_hop_route_map = bgp_af.default_next_hop_route_map
    af_string = get_bgp_af_cfg(asn, vrf, af)

    refute_match(pattern, af_string,
                 "Error: 'nexthop route-map drop_all' is " \
                   'configured and should not be')
  end

  ##
  ## additional_paths
  ##
  def test_additional_paths
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    bgp_af = RouterBgpAF.new(asn, vrf, af)

    pattern_send = 'additional-paths send'
    pattern_receive = 'additional-paths receive'
    pattern_install = 'additional-paths install backup'

    #
    # Default is not configured
    #
    af_string = get_bgp_af_cfg(asn, vrf, af)

    [pattern_send, pattern_receive, pattern_install].each do |pat|
      refute_match(pat, af_string,
                   "Error: '#{pat}' is configured but should not be")
    end

    #
    # Test default and getter methods
    #
    assert_equal(bgp_af.default_additional_paths_send,
                 bgp_af.additional_paths_send)
    assert_equal(bgp_af.default_additional_paths_receive,
                 bgp_af.additional_paths_receive)
    assert_equal(bgp_af.default_additional_paths_install,
                 bgp_af.additional_paths_install)

    #
    # Set and verify
    #

    # Do a 'additional-paths send, receive, install'
    bgp_af.additional_paths_send = true
    bgp_af.additional_paths_receive = true
    bgp_af.additional_paths_install = true

    af_string = get_bgp_af_cfg(asn, vrf, af)

    [pattern_send, pattern_receive, pattern_install].each do |pat|
      assert_match(pat, af_string,
                   "Error: '#{pat}' is not configured and should be")
    end

    #
    # Test getter
    #

    assert(bgp_af.additional_paths_send)
    assert(bgp_af.additional_paths_receive)
    assert(bgp_af.additional_paths_install)

    #
    # Unset and verify
    #

    # Do a 'no additional-paths send, receive, install'
    bgp_af.additional_paths_send = false
    bgp_af.additional_paths_receive = false
    bgp_af.additional_paths_install = false

    af_string = get_bgp_af_cfg(asn, vrf, af)

    [pattern_send, pattern_receive, pattern_install].each do |pat|
      refute_match(pat, af_string,
                   "Error: '#{pat}' is configured but should not be")
    end
  end

  ##
  ## additional_paths_selection route-map
  ##
  def test_additional_paths_selection
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.additional_paths_selection = 'drop_all'

    assert_equal(bgp_af.additional_paths_selection, 'drop_all',
                 'Error: additional-paths selection route-map not set')

    af_string = get_bgp_af_cfg(asn, vrf, af)
    pattern = /^ *additional-paths selection route-map drop_all$/

    assert_match(pattern, af_string,
                 "Error: 'additional-paths selection route-map drop_all' is " \
                   'not configured and should be')

    #
    # Test getter
    #
    pattern = /^ *drop_all$/
    assert_match(pattern, bgp_af.additional_paths_selection,
                 "Error: 'route-map drop_all' is not configured and should be")

    #
    # Unset and verify
    #

    # Do a 'no additional-paths selection route-map drop_all'
    bgp_af.additional_paths_selection =
      bgp_af.default_additional_paths_selection

    af_string = get_bgp_af_cfg(asn, vrf, af)

    refute_match(pattern, af_string,
                 "Error: 'additional-paths selection route-map drop_all' is " \
                   'configured and should not be')
  end

  ##
  ## advertise_l2vpn_evpn
  ##
  def advertise_l2vpn_evpn(asn, vrf, af)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify
    #
    val = false
    bgp_af.advertise_l2vpn_evpn = val
    assert_equal(val, bgp_af.advertise_l2vpn_evpn,
                 'Error: advertise l2vpn evpn value does not match set value')

    val = true
    bgp_af.advertise_l2vpn_evpn = val
    assert_equal(val, bgp_af.advertise_l2vpn_evpn,
                 'Error: advertise l2vpn evpn value does not match set value')

    val = bgp_af.default_advertise_l2vpn_evpn
    bgp_af.advertise_l2vpn_evpn = val
    assert_equal(val, bgp_af.advertise_l2vpn_evpn,
                 'Error: advertise l2vpn evpn value does not match default' \
                 'value')
  end

  def test_advertise_l2vpn_evpn
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    afs.each do |af|
      advertise_l2vpn_evpn(55, 'red', af)
    end
  end

  ##
  ## get_dampen_igp_metric
  ##
  def test_dampen_igp_metric
    asn = '44'
    vrf = 'green'
    af = %w(ipv4 multicast)

    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Verify default value
    #
    assert_equal(bgp_af.dampen_igp_metric, bgp_af.default_dampen_igp_metric,
                 "Error: Default 'dampen-igp-metric' value should be " \
                   "#{bgp_af.default_dampen_igp_metric}")

    #
    # Set and verify 'dampen-igp-metric <value>'
    #

    # Do a 'dampen-igp-metric 555'
    pattern = /^ *dampen-igp-metric 555$/
    bgp_af.dampen_igp_metric = 555

    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'dampen-igp-metric 555' is not configured " \
                   'and should be')
    #
    # Test getter
    #
    assert_equal(bgp_af.dampen_igp_metric, 555,
                 'Error: dampen_igp_metric should be 555')

    #
    # Set and verify 'no dampen-igp-metric'
    #

    # Do a 'no dampen-igp-metric'
    pattern = /no dampen-igp-metric$/
    bgp_af.dampen_igp_metric = nil

    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'no dampen-igp-metric' is not configured " \
                   'and should be')
    #
    # Test getter
    #
    assert_equal(bgp_af.dampen_igp_metric, nil,
                 'Error: dampen_igp_metric should be nil')

    #
    # Set default value explicitly
    #
    bgp_af.dampen_igp_metric = bgp_af.default_dampen_igp_metric
    assert_equal(bgp_af.dampen_igp_metric, bgp_af.default_dampen_igp_metric,
                 "Error: Default 'dampen-igp-metric' value should be " \
                   "#{bgp_af.default_dampen_igp_metric}")
  end

  ##
  ## dampening
  ##
  # rubocop:disable Metrics/MethodLength
  def test_dampening
    asn = '101'

    ############################################
    # Set and verify 'dampening' with defaults #
    ############################################
    vrf = 'orange'
    af = %w(ipv4 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    # Test no dampening configured
    assert_nil(bgp_af.dampening)

    pattern = /^ *dampening$/

    bgp_af.dampening = []

    # Check property got set
    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'dampening' is not configured and should be")

    # Check properties got set
    af_string = get_bgp_af_dampening_params(asn, vrf, af)

    pattern_params1 = 'Half-life time                 : 15 mins'
    pattern_params2 = 'Suppress penalty               : 2000'
    pattern_params3 = 'Reuse penalty                  : 750'
    pattern_params4 = 'Max suppress time              : 45 mins'
    pattern_params5 = 'Max suppress penalty           : 6000'

    error = ("Error: 'dampening' properties are incorrect")

    assert_match(pattern_params1, af_string, error)
    assert_match(pattern_params2, af_string, error)
    assert_match(pattern_params3, af_string, error)
    assert_match(pattern_params4, af_string, error)
    assert_match(pattern_params5, af_string, error)

    # Check getter
    assert_empty(bgp_af.dampening, 'Error: dampening is configured and ' \
                 'should not be')

    #
    # Unset and verify
    #
    bgp_af.dampening = nil

    af_string = get_bgp_af_cfg(asn, vrf, af)
    pattern = /^ *dampening$/

    refute_match(pattern, af_string, "Error: 'dampening' is still configured")

    #
    # Test Getters
    #
    assert_nil(bgp_af.dampening)
    assert_nil(bgp_af.dampening_half_time)
    assert_nil(bgp_af.dampening_reuse_time)
    assert_nil(bgp_af.dampening_suppress_time)
    assert_nil(bgp_af.dampening_max_suppress_time)
    assert_nil(bgp_af.dampening_routemap)

    bgp_af.destroy

    #############################################
    # Set and verify 'dampening' with overrides #
    #############################################
    vrf = 'green'
    af = %w(ipv4 multicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    bgp_af.dampening = %w(1 2 3 4)

    # Check property got set
    af_string = get_bgp_af_cfg(asn, vrf, af)
    pattern = /^ *dampening 1 2 3 4$/

    assert_match(pattern, af_string,
                 "Error: 'dampening' is not configured and should be")

    # Check properties got set
    af_string = get_bgp_af_dampening_params(asn, vrf, af)

    pattern_params1 = 'Half-life time                 : 1 mins'
    pattern_params2 = 'Suppress penalty               : 3'
    pattern_params3 = 'Reuse penalty                  : 2'
    pattern_params4 = 'Max suppress time              : 4 mins'
    pattern_params5 = 'Max suppress penalty           : 32'

    error = ("Error: 'dampening' properties are incorrect")

    assert_match(pattern_params1, af_string, error)
    assert_match(pattern_params2, af_string, error)
    assert_match(pattern_params3, af_string, error)
    assert_match(pattern_params4, af_string, error)
    assert_match(pattern_params5, af_string, error)

    # Check getters
    assert_equal(bgp_af.dampening, %w(1 2 3 4),
                 'Error: dampening getter did not match')
    assert_equal(1, bgp_af.dampening_half_time,
                 'The wrong dampening half_time value is configured')
    assert_equal(2, bgp_af.dampening_reuse_time,
                 'The wrong dampening reuse_time value is configured')
    assert_equal(3, bgp_af.dampening_suppress_time,
                 'The wrong dampening suppress_time value is configured')
    assert_equal(4, bgp_af.dampening_max_suppress_time,
                 'The wrong dampening max_suppress_time value is configured')
    assert_empty(bgp_af.dampening_routemap,
                 'A routemap should not be configured')

    #
    # Unset and verify
    #
    bgp_af.dampening = nil

    af_string = get_bgp_af_cfg(asn, vrf, af)
    pattern = /^ *dampening$/

    refute_match(pattern, af_string, "Error: 'dampening' is still configured")

    #############################################
    # Set and verify 'dampening' with route-map #
    #############################################
    vrf = 'brown'
    af = %w(ipv6 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    bgp_af.dampening = 'DropAllTraffic'

    pattern = /^ *dampening route-map DropAllTraffic$/

    # Check property got set
    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'dampening' is not configured and should be")

    # Check properties got set
    af_string = get_bgp_af_dampening_params(asn, vrf, af)
    pattern_params = 'Dampening policy configured: DropAllTraffic'

    assert_match(pattern_params, af_string,
                 'Error: dampening properties DropAllTraffic is not ' \
                   'configured and should be')

    # Check getters
    assert_equal(bgp_af.dampening, 'DropAllTraffic',
                 'Error: dampening getter did not match')
    assert_equal(bgp_af.dampening_routemap, 'DropAllTraffic',
                 'Error: dampening getter did not match')

    #
    # Unset and verify
    #
    bgp_af.dampening = nil
    af_string = get_bgp_af_cfg(asn, vrf, af)
    pattern = /^ *dampening$/

    refute_match(pattern, af_string, "Error: 'dampening' is still configured")

    #############################################
    # Set and verify 'dampening' with default   #
    #############################################
    vrf = 'sangria'
    af = %w(ipv4 multicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    bgp_af.dampening = bgp_af.default_dampening

    # Check property got set
    af_string = get_bgp_af_cfg(asn, vrf, af)

    assert_match(pattern, af_string,
                 "Error: 'dampening' is not configured and should be")

    # Check properties got set
    af_string = get_bgp_af_dampening_params(asn, vrf, af)

    pattern_params1 = 'Half-life time                 : 15 mins'
    pattern_params2 = 'Suppress penalty               : 2000'
    pattern_params3 = 'Reuse penalty                  : 750'
    pattern_params4 = 'Max suppress time              : 45 mins'
    pattern_params5 = 'Max suppress penalty           : 6000'

    error = ("Error: 'dampening' properties are incorrect")

    assert_match(pattern_params1, af_string, error)
    assert_match(pattern_params2, af_string, error)
    assert_match(pattern_params3, af_string, error)
    assert_match(pattern_params4, af_string, error)
    assert_match(pattern_params5, af_string, error)

    # Check getters
    assert_empty(bgp_af.dampening, 'Error: dampening not configured ' \
                 'and should be')
    assert_equal(bgp_af.default_dampening_half_time, bgp_af.dampening_half_time,
                 'Wrong default dampening half_time value configured')
    assert_equal(bgp_af.default_dampening_reuse_time,
                 bgp_af.dampening_reuse_time,
                 'Wrong default dampening reuse_time value configured')
    assert_equal(bgp_af.default_dampening_suppress_time,
                 bgp_af.dampening_suppress_time,
                 'Wrong default dampening suppress_time value configured')
    assert_equal(bgp_af.default_dampening_max_suppress_time,
                 bgp_af.dampening_max_suppress_time,
                 'Wrong default dampening suppress_max_time value configured')
    assert_equal(bgp_af.default_dampening_routemap,
                 bgp_af.dampening_routemap,
                 'The default dampening routemap should configured')

    #
    # Unset and verify
    #
    bgp_af.dampening = nil
    af_string = get_bgp_af_cfg(asn, vrf, af)

    refute_match(pattern, af_string, "Error: 'dampening' is still configured")
  end
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength

  ##
  ## distance
  ##
  def test_distance
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    bgp_af = RouterBgpAF.new(asn, vrf, af)
    distance = [{ ebgp: 20, ibgp: 40, local: 60 },
                { ebgp:  bgp_af.default_distance_ebgp,
                  ibgp:  bgp_af.default_distance_ibgp,
                  local: bgp_af.default_distance_local },
                { ebgp:  bgp_af.default_distance_ebgp,
                  ibgp:  40,
                  local: 60 },
                { ebgp:  20,
                  ibgp:  bgp_af.default_distance_ibgp,
                  local: bgp_af.default_distance_local },
                { ebgp:  bgp_af.default_distance_ebgp,
                  ibgp:  bgp_af.default_distance_ibgp,
                  local: 60 },
               ]
    distance.each do |distancer|
      bgp_af.distance_set(distancer[:ebgp], distancer[:ibgp], distancer[:local])
      assert_equal(distancer[:ebgp], bgp_af.distance_ebgp)
      assert_equal(distancer[:ibgp], bgp_af.distance_ibgp)
      assert_equal(distancer[:local], bgp_af.distance_local)
    end
    bgp_af.destroy
  end

  ##
  ## default_metric
  ##
  def default_metric(asn, vrf, af)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    refute(bgp_af.default_default_metric,
           'default value for default default metric should be false')
    #
    # Set and verify
    #
    val = 50
    bgp_af.default_metric = val
    assert_equal(val, bgp_af.default_metric,
                 'Error: default metric value does not match set value')

    val = bgp_af.default_default_metric
    bgp_af.default_metric = val
    assert_equal(val, bgp_af.default_metric,
                 'Error: default metric value does not match default' \
                 'value')
  end

  def test_default_metric
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    afs.each do |af|
      default_metric(55, 'red', af)
    end
  end

  ##
  ## inject_map
  ##
  def inject_map(asn, vrf, af)
    # rubocop:disable Style/WordArray
    master = [['lax', 'sfo'],
              ['lax', 'sjc'],
              ['nyc', 'sfo', 'copy-attributes'],
              ['sjc', 'nyc', 'copy-attributes']]
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    # Test1: both/import/export when no commands are present. Each target
    # option will be tested with and without evpn (6 separate types)
    should = master.clone
    inject_map_tester(bgp_af, should, 'Test 1')

    # Test 2: remove half of the entries
    should = [['lax', 'sfo'], ['nyc', 'sfo', 'copy-attributes']]
    # rubocop:enable Style/WordArray
    inject_map_tester(bgp_af, should, 'Test 2')

    # Test 3: restore the removed entries
    should = master.clone
    inject_map_tester(bgp_af, should, 'Test 3')

    # Test 4: 'default'
    should = bgp_af.default_inject_map
    inject_map_tester(bgp_af, should, 'Test 4')
  end

  def inject_map_tester(bgp_af, should, test_id)
    bgp_af.send('inject_map=', should)
    result = bgp_af.send('inject_map')
    assert_equal(should, result,
                 "#{test_id} : inject_map")
  end

  def test_inject_map
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    afs.each do |af|
      inject_map(55, 'red', af)
    end
  end

  ##
  ## maximum_paths
  ##
  def maximum_paths(asn, vrf, af)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify
    #
    val = 7
    bgp_af.maximum_paths = val
    assert_equal(bgp_af.maximum_paths, val,
                 'Error: maximum paths value not match to set value')

    val = 9
    bgp_af.maximum_paths = val
    assert_equal(bgp_af.maximum_paths, val,
                 'Error: maximum paths value not match to set value')

    val = bgp_af.default_maximum_paths
    bgp_af.maximum_paths = val
    assert_equal(bgp_af.maximum_paths, val,
                 'Error: maximum paths value not match to default value')
  end

  def test_maximum_paths
    vrfs = %w(default red)
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    vrfs.each do |vrf|
      afs.each do |af|
        maximum_paths(55, vrf, af)
      end
    end
  end

  ##
  ## maximum_paths_ibgp
  ##
  def maximum_paths_ibgp(asn, vrf, af)
    /ipv4/.match(af) ? af = %w(ipv4 unicast) : af = %w(ipv6 unicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify
    #
    val = 7
    bgp_af.maximum_paths_ibgp = val
    assert_equal(bgp_af.maximum_paths_ibgp, val,
                 'Error: maximum paths ibgp value not match to set value')

    val = 9
    bgp_af.maximum_paths_ibgp = val
    assert_equal(bgp_af.maximum_paths_ibgp, val,
                 'Error: maximum paths ibgp value not match to set value')

    val = bgp_af.default_maximum_paths_ibgp
    bgp_af.maximum_paths = val
    assert_equal(bgp_af.default_maximum_paths_ibgp, val,
                 'Error: maximum paths ibgp value not match to default value')
  end

  def test_maximum_paths_ibgp
    asn = '55'
    vrf = 'default'
    af = 'ipv4 unicast'
    maximum_paths_ibgp(asn, vrf, af)

    asn = '55'
    vrf = 'red'
    af = 'ipv4 unicast'
    maximum_paths_ibgp(asn, vrf, af)

    asn = '55'
    vrf = 'default'
    af = 'ipv6 unicast'
    maximum_paths_ibgp(asn, vrf, af)

    asn = '55'
    vrf = 'red'
    af = 'ipv6 unicast'
    maximum_paths_ibgp(asn, vrf, af)
  end

  ##
  ## network
  ##

  def test_network
    vrfs = %w(default red)
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    vrfs.each do |vrf|
      afs.each do |af|
        dbg = sprintf('[VRF %s AF %s]', vrf, af.join('/'))
        af_obj = RouterBgpAF.new(1, vrf, af)
        network_cmd(af_obj, dbg)
      end
    end
  end

  def network_cmd(af, dbg)
    # Initial 'should' state
    if /ipv6/.match(dbg)
      master = [
        ['2000:123:38::/64', 'rtmap1'],
        ['2000:123:39::/64', 'rtmap2'],
        ['2000:123:40::/64', 'rtmap3'],
        ['2000:123:41::/64'],
        ['2000:123:42::/64', 'rtmap5'],
        ['2000:123:43::/64', 'rtmap6'],
        ['2000:123:44::/64'],
        ['2000:123:45::/64', 'rtmap7'],
      ]
    else
      master = [
        ['192.168.5.0/24', 'rtmap1'],
        ['192.168.6.0/24', 'rtmap2'],
        ['192.168.7.0/24', 'rtmap3'],
        ['192.168.8.0/24'],
        ['192.168.9.0/24', 'rtmap5'],
        ['192.168.10.0/24', 'rtmap6'],
        ['192.168.11.0/24'],
        ['192.168.12.0/24', 'rtmap7'],
      ]
    end

    # Test: all networks are set when current is empty.
    should = master.clone
    af.networks = should
    result = af.networks
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 1. From empty, to all networks")

    # Test: remove half of the networks
    should.shift(4)
    af.networks = should
    result = af.networks
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 2. Remove half of the networks")

    # Test: restore the removed networks
    should = master.clone
    af.networks = should
    result = af.networks
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 3. Restore the removed networks")

    # Test: Change route-maps on existing networks
    should = master.map { |network, rm| [network, "#{rm}_55"] }
    af.networks = should
    result = af.networks
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 4. Change route-map on existing networks")

    # Test: 'default'
    should = af.default_networks
    af.networks = should
    result = af.networks
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 5. 'Default'")
  end

  ##
  ## redistribute
  ##

  def test_redistribute
    vrfs = %w(default red)
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    vrfs.each do |vrf|
      afs.each do |af|
        dbg = sprintf('[VRF %s AF %s]', vrf, af.join('/'))
        af = RouterBgpAF.new(1, vrf, af)
        redistribute_cmd(af, dbg)
      end
    end
  end

  def redistribute_cmd(af, dbg)
    # rubocop:disable Style/WordArray
    # Initial 'should' state
    ospf = (dbg.include? 'ipv6') ? 'ospfv3 3' : 'ospf 3'
    master = [['direct',  'rm_direct'],
              ['lisp',    'rm_lisp'],
              ['static',  'rm_static'],
              ['eigrp 1', 'rm_eigrp'],
              ['isis 2',  'rm_isis'],
              [ospf,      'rm_ospf'],
              ['rip 4',   'rm_rip']]
    # rubocop:enable Style/WordArray

    # Test: Add all protocols w/route-maps when no cmds are present
    should = master.clone
    af.redistribute = should
    result = af.redistribute
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 1. From empty, to all protocols")

    # Test: remove half of the protocols
    should.shift(4)
    af.redistribute = should
    result = af.redistribute
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 2. Remove half of the protocols")

    # Test: restore the removed protocols
    should = master.clone
    af.redistribute = should
    result = af.redistribute
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 3. Restore the removed protocols")

    # Test: Change route-maps on existing commands
    should = master.map { |prot_only, rm| [prot_only, "#{rm}_2"] }
    af.redistribute = should
    result = af.redistribute
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 4. Change route-maps on existing commands")

    # Test: 'default'
    should = af.default_redistribute
    af.redistribute = should
    result = af.redistribute
    assert_equal(should.sort, result.sort,
                 "#{dbg} Test 5. 'Default'")
  end

  ##
  ## common utilities
  ##
  def test_utils_delta_add_remove_depth_1
    # Note: AF context is not needed. This test is only validating the
    # delta_add_remove class method and does not test directly on the device.

    # Initial 'should' state
    should = ['1:1', '2:2', '3:3', '4:4', '5:5', '6:6']
    # rubocop:enable Style/WordArray

    # Test: Check delta when every protocol is specified and has a route-map.
    current = []
    expected = { add: should, remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 1. delta mismatch')

    # Test: Check delta when should is the same as current.
    current = should.clone
    expected = { add: [], remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 2. delta mismatch')

    # Test: Move half the 'current' entries to 'should'. Check delta.
    should = current.shift(4)
    expected = { add: should, remove: current }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 3. delta mismatch')

    # Test: Remove the route-maps from the current list. Check delta.
    #       Note: The :remove list should be empty since this is just
    #       an update of the route-map.
    should = current.map { |prot_only, _route_map| [prot_only] }
    expected = { add: should, remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 4. delta mismatch')

    # Test: Check empty inputs
    should = []
    current = []
    expected = { add: [], remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 5. delta mismatch')
  end

  def test_utils_delta_add_remove
    # Note: AF context is not needed. This test is only validating the
    # delta_add_remove class method and does not test directly on the device.

    # rubocop:disable Style/WordArray
    # Initial 'should' state
    should = [['direct',  'rm_direct'],
              ['lisp',    'rm_lisp'],
              ['static',  'rm_static'],
              ['eigrp 1', 'rm_eigrp'],
              ['isis 2',  'rm_isis'],
              ['ospf 3',  'rm_ospf'],
              ['rip 4',   'rm_rip']]
    # rubocop:enable Style/WordArray

    # Test: Check delta when every protocol is specified and has a route-map.
    current = []
    expected = { add: should, remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 1. delta mismatch')

    # Test: Check delta when should is the same as current.
    current = should.clone
    expected = { add: [], remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 2. delta mismatch')

    # Test: Move half the 'current' entries to 'should'. Check delta.
    should = current.shift(4)
    expected = { add: should, remove: current }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 3. delta mismatch')

    # Test: Remove the route-maps from the current list. Check delta.
    #       Note: The :remove list should be empty since this is just
    #       an update of the route-map.
    should = current.map { |prot_only, _route_map| [prot_only] }
    expected = { add: should, remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 4. delta mismatch')

    # Test: Check empty inputs
    should = []
    current = []
    expected = { add: [], remove: [] }
    result = Utils.delta_add_remove(should, current)
    assert_equal(expected, result, 'Test 5. delta mismatch')
  end

  ##
  ## suppress_inactive
  ##
  def suppress_inactive(asn, vrf, af)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify
    #
    val = false
    bgp_af.suppress_inactive = val
    refute(bgp_af.suppress_inactive,
           'Error: suppress inactive value does not match set value')

    val = true
    bgp_af.suppress_inactive = val
    assert(bgp_af.suppress_inactive,
           'Error: suppress inactive value does not match set value')

    val = bgp_af.default_suppress_inactive
    bgp_af.suppress_inactive = val
    refute(bgp_af.suppress_inactive,
           'Error: suppress inactive value does not match default value')
  end

  def test_suppress_inactive
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    afs.each do |af|
      suppress_inactive(55, 'red', af)
    end
  end

  ##
  ## table_map
  ##
  def table_map(asn, vrf, af)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    #
    # Set and verify
    #
    val = 'sjc'
    bgp_af.table_map_set(val)
    assert_equal(val, bgp_af.table_map,
                 'Error: default metric value does not match set value')

    val = bgp_af.default_table_map
    bgp_af.table_map_set(val)
    assert_equal(val, bgp_af.table_map,
                 'Error: default metric value does not match default' \
                 'value')

    val = false
    bgp_af.table_map_set('sjc', val)
    refute(bgp_af.table_map_filter,
           'Error: suppress inactive value does not match set value')

    val = true
    bgp_af.table_map_set('sjc', val)
    assert(bgp_af.table_map_filter,
           'Error: suppress inactive value does not match set value')

    val = bgp_af.default_table_map_filter
    bgp_af.table_map_set('sjc', val)
    refute(bgp_af.table_map_filter,
           'Error: suppress inactive value does not match default value')
  end

  def test_table_map
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    afs.each do |af|
      table_map(55, 'red', af)
    end
  end
end
