#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/bgp'
require_relative '../lib/cisco_node_utils/bgp_af'

# TestRouterBgpAF - Minitest for RouterBgpAF class
class TestRouterBgpAF < CiscoTestCase
  def setup
    super
    # Disable and enable feature bgp before each test to ensure we
    # are starting with a clean slate for each test.
    if platform == :nexus
      config('no feature bgp', 'feature bgp')
    elsif platform == :ios_xr
      config('no router bgp')
    end
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
    config('feature bgp') if platform == :nexus
    config('router bgp 55',
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

  def config_ios_xr_dependencies(asn)
    # These dependencies are required on ios xr

    # router bgp 55
    #  vrf red
    #   address-family ipv4 unicast
    # !!% 'BGP' detected the 'warning' condition 'The RD for the VRF must
    #    be present before an address family is activated'

    # router bgp 55
    #  vrf red
    #   rd auto
    # !!% 'BGP' detected the 'warning' condition 'BGP router ID must be
    #     configured.'
    # Configure loopback0 with ip 10.1.1.1 and
    # router bgp 55
    #  bgp router-id 10.1.1.1

    # router bgp 55
    #  vrf red
    #   address-family ipv4 unicast
    # !!% 'BGP' detected the 'warning' condition 'The parent address family
    #     has not been initialized'
    # Configure
    # router bgp 55
    #  address-family vpnv4 unicast

    config('interface Loopback0', 'ipv4 address 10.1.1.1 255.255.255.255')
    config("router bgp #{asn}",
           'bgp router-id 10.1.1.1',
           'address-family vpnv4 unicast',
           'address-family vpnv6 unicast',
           'vrf red', 'rd auto')
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

    config_ios_xr_dependencies(asn) if platform == :ios_xr

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.default_information_originate = true
    assert(bgp_af.default_information_originate,
           'Error: default-information originate not set')

    pattern = /^ *default-information originate$/
    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} vrf #{vrf} " \
                              'default-information originate')
    end
    assert_match(pattern, af_string,
                 "Error: 'default_information originate' is not" \
                   ' configured and should be')

    #
    # Unset and verify
    #

    # Do a 'no default-information originate'
    bgp_af.default_information_originate = false

    pattern = /^ *default-information originate$/
    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} vrf #{vrf} " \
                              'default-information originate')
    end

    refute_match(pattern, af_string,
                 "Error: 'default_information originate' " \
                   'is configured and should not be')
  end

  ##
  ## client-to-client reflection
  ##
  def test_client_to_client
    asn = '55'
    vrf = 'default'
    af = %w(ipv4 unicast)
    config_ios_xr_dependencies(asn) if platform == :ios_xr
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    if platform == :ios_xr
      #
      # Default is:
      #   client-to-client reflection enabled but doesn't show up in config
      # router bgp 55
      #  address-family ipv4 unicast
      #   bgp client-to-client reflection disable
      #
      pattern = /^ *bgp client-to-client reflection disable$/
      af_string = @device.cmd("show run router bgp #{asn} address-family " \
                              'ipv4 unicast bgp client-to-client ' \
                              'reflection disable')
      refute_match(pattern, af_string,
                   'bgp client-to-client disable is configured ' \
                   'but should not be')
    elsif platform == :nexus
      pattern = /^ *client-to-client reflection$/
      #
      # Default is 'client-to-client' is configured
      #
      af_string = get_bgp_af_cfg(asn, vrf, af)

      assert_match(pattern, af_string,
                   "Error: 'client-to-client reflection' is not configured " \
                   'and should be')

      assert(bgp_af.client_to_client,
             "Error: 'client-to-client is not configured but should be")
    end

    #
    # Set and verify
    #
    bgp_af.client_to_client = true
    if platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} address-family " \
                              'ipv4 unicast bgp client-to-client ' \
                              'reflection disable')

      pattern = /^ *bgp client-to-client reflection disable$/
      assert_match(pattern, af_string,
                   'bgp client-to-client disable is configured and should be')
    elsif platform == :nexus
      # Do a 'client-to-client reflection'
      af_string = get_bgp_af_cfg(asn, vrf, af)
      pattern = /^ *client-to-client reflection$/

      refute_match(pattern, af_string,
                   "Error: 'no client-to-client' " \
                   'is configured and should not be')
    end

    #
    # Unset and verify
    #
    bgp_af.client_to_client = false
    if platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} address-family " \
                              'ipv4 unicast bgp client-to-client ' \
                              'reflection disable')
      pattern = /^ *bgp client-to-client reflection disable$/
      refute_match(pattern, af_string,
                   'bgp client-to-client disable is configured ' \
                   'but should not be')
    elsif platform == :nexus
      # Do a 'no client-to-client reflection'
      pattern = /^ *no client-to-client reflection$/
      af_string = get_bgp_af_cfg(asn, vrf, af)

      assert_match(pattern, af_string,
                   "Error: 'no client-to-client' " \
                   'is not configured and should be')
    end
  end

  ##
  ## next_hop route-map or route-policy
  ##
  def test_next_hop_route_map_or_policy
    asn = '55'
    if platform == :nexus
      vrf = 'red'
    elsif platform == :ios_xr
      vrf = 'default'
    end
    af = %w(ipv4 unicast)

    #
    # Set and verify
    #
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    if platform == :nexus
      bgp_af.next_hop_route_map = 'drop_all'
    elsif platform == :ios_xr
      config('route-policy drop_all', 'end') if platform == :ios_xr
      bgp_af.next_hop_route_policy = 'drop_all'
    end

    if platform == :nexus
      assert_match(bgp_af.next_hop_route_map, 'drop_all',
                   'Error: nexthop route-map not set')
      pattern = /^ *nexthop route-map drop_all$/
      af_string = get_bgp_af_cfg(asn, vrf, af)

      assert_match(pattern, af_string,
                   "Error: 'nexthop route-map drop_all' is " \
                   'not configured and should be')
    elsif platform == :ios_xr
      assert_match(bgp_af.next_hop_route_policy, 'drop_all',
                   'Error: nexthop route-policy not set')
      pattern = /^ *nexthop route-policy drop_all$/
      af_string = @device.cmd("show run router bgp #{asn} address-family " \
                              'ipv4 unicast nexthop route-policy drop_all')

      assert_match(pattern, af_string,
                   "Error: 'nexthop route-policy drop_all' is " \
                   'not configured and should be')
    end

    #
    # Unset and verify
    #

    # Do a 'no nexthop route-map drop_all'
    if platform == :nexus
      bgp_af.next_hop_route_map = bgp_af.default_next_hop_route_map
      af_string = get_bgp_af_cfg(asn, vrf, af)

      refute_match(pattern, af_string,
                   "Error: 'nexthop route-map drop_all' is " \
                   'configured and should not be')
    elsif platform == :ios_xr
      bgp_af.next_hop_route_policy = bgp_af.default_next_hop_route_policy
      af_string = @device.cmd("show run router bgp #{asn} address-family " \
                              'ipv4 unicast nexthop route-policy drop_all')

      refute_match(pattern, af_string,
                   "Error: 'nexthop route-policy drop_all' is " \
                   'configured and should not be')
      config('no route-policy drop_all')
    end
  end

  ##
  ## additional_paths
  ##
  def test_additional_paths
    asn = '55'
    vrf = 'red'
    af = %w(ipv4 unicast)

    config_ios_xr_dependencies(asn) if platform == :ios_xr

    bgp_af = RouterBgpAF.new(asn, vrf, af)

    pattern_send = 'additional-paths send'
    pattern_receive = 'additional-paths receive'
    pattern_install = 'additional-paths install backup'

    #
    # Default is not configured
    #
    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} vrf #{vrf} " \
                              'address-family ipv4 unicast')
    end

    patterns = [pattern_send, pattern_receive]
    patterns.push pattern_install if platform == :nexus

    patterns.each do |pat|
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
    bgp_af.additional_paths_install = true if platform == :nexus

    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} vrf #{vrf} " \
                              'address-family ipv4 unicast')
    end

    patterns.each do |pat|
      assert_match(pat, af_string,
                   "Error: '#{pat}' is not configured and should be")
    end

    #
    # Test getter
    #

    assert(bgp_af.additional_paths_send,
           'No additional-paths send configured')
    assert(bgp_af.additional_paths_receive,
           'No additional-paths receive configured')
    assert(bgp_af.additional_paths_install) if platform == :nexus

    #
    # Unset and verify
    #

    # Do a 'no additional-paths send, receive, install'
    bgp_af.additional_paths_send = false
    bgp_af.additional_paths_receive = false
    bgp_af.additional_paths_install = false if platform == :nexus

    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} vrf #{vrf} " \
                              'address-family ipv4 unicast')
    end

    patterns.each do |pat|
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
    if platform == :ios_xr
      config_ios_xr_dependencies(asn)
      config('route-policy drop_all', 'end')
    end
    bgp_af = RouterBgpAF.new(asn, vrf, af)
    bgp_af.additional_paths_selection = 'drop_all'

    assert_equal(bgp_af.additional_paths_selection, 'drop_all',
                 'Error: additional-paths selection route-map/policy not set')

    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
      pattern = /^ *additional-paths selection route-map drop_all$/
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} vrf #{vrf} " \
                              'address-family ipv4 unicast')
      pattern = /^ *additional-paths selection route-policy drop_all$/
    end

    assert_match(pattern, af_string,
                 "Error: 'additional-paths selection route-map/policy " \
                 "drop_all' is not configured and should be")

    #
    # Test getter
    #
    pattern = /^ *drop_all$/
    assert_match(pattern, bgp_af.additional_paths_selection,
                 "Error: 'route-map/policy drop_all' " \
                 'is not configured and should be')

    #
    # Unset and verify
    #

    # Do a 'no additional-paths selection route-map drop_all'
    bgp_af.additional_paths_selection =
      bgp_af.default_additional_paths_selection

    af_string = get_bgp_af_cfg(asn, vrf, af)
    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} vrf #{vrf} " \
                              'address-family ipv4 unicast')
    end

    refute_match(pattern, af_string,
                 "Error: 'additional-paths selection route-map drop_all' is " \
                   'configured and should not be')
    config('no route-policy drop_all') if platform == :ios_xr
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
    skip('L2VPN EVPN is unsupported on IOS XR') if platform == :ios_xr
    afs = [%w(ipv4 unicast), %w(ipv6 unicast)]
    afs.each do |af|
      advertise_l2vpn_evpn(55, 'red', af)
    end
  end

  ##
  ## get_dampen_igp_metric
  ##
  def test_dampen_igp_metric
    skip('dampen-igp-metric unsupported on IOS XR') if platform == :ios_xr
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
    if platform == :nexus
      vrf = 'orange'
    elsif platform == :ios_xr
      vrf = 'default'
    end
    af = %w(ipv4 unicast)
    config_ios_xr_dependencies(asn) if platform == :ios_xr
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    # Test no dampening configured
    assert_nil(bgp_af.dampening)

    if platform == :nexus
      pattern = /^ *dampening$/
    elsif platform == :ios_xr
      pattern = /^ *bgp dampening$/
    end

    bgp_af.dampening = []

    # Check property got set
    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} " \
                              'address-family ipv4 unicast bgp dampening')
    end

    assert_match(pattern, af_string,
                 "Error: 'dampening' is not configured and should be")

    if platform == :nexus

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
    end
    # "show bgp dampening param not supported on IOS XR"

    #
    # Unset and verify
    #
    bgp_af.dampening = nil

    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
      pattern = /^ *dampening$/
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} " \
                              'address-family ipv4 unicast bgp dampening')
      pattern = /^ *bgp dampening$/
    end

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
    if platform == :nexus
      vrf = 'green'
    elsif platform == :ios_xr
      vrf = 'default'
    end
    af = %w(ipv4 multicast)
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    bgp_af.dampening = %w(1 2 3 4)

    # Check property got set
    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
      pattern = /^ *dampening 1 2 3 4$/
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} " \
                              "address-family #{af[0]} #{af[1]}")
      pattern = /^ *bgp dampening 1 2 3 4$/
    end

    assert_match(pattern, af_string,
                 "Error: 'dampening' is not configured and should be")

    if platform == :nexus
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
    end

    #
    # Unset and verify
    #
    bgp_af.dampening = nil

    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
      pattern = /^ *dampening$/
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} " \
                              'address-family ipv4 unicast bgp dampening')
      pattern = /^ *bgp dampening$/
    end

    refute_match(pattern, af_string, "Error: 'dampening' is still configured")

    #############################################
    # Set and verify 'dampening' with route-map #
    #############################################
    if platform == :nexus
      vrf = 'brown'
      af = %w(ipv6 unicast)
    elsif platform == :ios_xr
      vrf = 'default'
      af = %w(ipv4 unicast)
      config('route-policy DropAllTraffic', 'end')
    end
    bgp_af = RouterBgpAF.new(asn, vrf, af)

    bgp_af.dampening = 'DropAllTraffic'

    # Check property got set
    if platform == :nexus
      pattern = /^ *dampening route-map DropAllTraffic$/
      af_string = get_bgp_af_cfg(asn, vrf, af)
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} " \
                              'address-family ipv4 unicast bgp dampening')
      pattern = /^ *bgp dampening route-policy DropAllTraffic$/
    end

    assert_match(pattern, af_string,
                 "Error: 'dampening' is not configured and should be")

    # Check properties got set
    if platform == :nexus
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
    end

    #
    # Unset and verify
    #
    bgp_af.dampening = nil

    if platform == :nexus
      af_string = get_bgp_af_cfg(asn, vrf, af)
      pattern = /^ *dampening$/
    elsif platform == :ios_xr
      af_string = @device.cmd("show run router bgp #{asn} " \
                              'address-family ipv4 unicast bgp dampening')
      pattern = /^ *bgp dampening$/
    end

    refute_match(pattern, af_string, "Error: 'dampening' is still configured")

    config('no route-policy DropAllTraffic') if platform == :ios_xr

    #############################################
    # Set and verify 'dampening' with default   #
    #############################################
    return if platform == :ios_xr
    # the rest is not supported on XR

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

  ## feature nv overlay evpn
  def test_feature_nv_overlay_evpn
    skip('nv overlay evpn unsupported on IOS XR') if platform == :ios_xr
    config('no nv overlay evpn')
    RouterBgpAF.feature_nv_overlay_evpn_enable
    assert(RouterBgpAF.feature_nv_overlay_evpn_enabled,
           'Error:feature nv overlay evpn is not enabled')
  end

  ##
  ## maximum_paths
  ##
  def maximum_paths(asn, vrf, af)
    config_ios_xr_dependencies(asn) if platform == :ios_xr
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
    config_ios_xr_dependencies(asn) if platform == :ios_xr
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
        config_ios_xr_dependencies(1)
        af_obj = RouterBgpAF.new(1, vrf, af)
        network_cmd(af_obj, dbg)
      end
    end
  end

  def network_cmd(af, dbg)
    if platform == :ios_xr
      %w(rtmap1, rtmap2, rtmap3, rtmap5, rtmap6, rtmap7).each do |policy|
        config("route-policy #{policy}", 'end')
      end
    end
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
    if platform == :ios_xr
      %w(rtmap1_55, rtmap2_55, rtmap3_55, rtmap5_55,
         rtmap6_55, rtmap7_55).each do |policy|
        config("route-policy #{policy}", 'end')
      end
      should = master.map { |network, rm| [network, rm.nil? ? nil : "#{rm}_55"] }
    elsif platform == :nexus
      should = master.map { |network, rm| [network, "#{rm}_55"] }
    end
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
    %w(rtmap1, rtmap2, rtmap3, rtmap5, rtmap6, rtmap7,
       rtmap1_55, rtmap2_55, rtmap3_55,
       rtmap5_55, rtmap6_55, rtmap7_55).each do |policy|
      config("no route-policy #{policy}")
    end if platform == :ios_xr
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
        config_ios_xr_dependencies(1) if platform == :ios_xr
        af = RouterBgpAF.new(1, vrf, af)
        redistribute_cmd(af, dbg)
      end
    end
  end

  def redistribute_cmd(af, dbg)
    # rubocop:disable Style/WordArray
    # Initial 'should' state
    ospf = (dbg.include? 'ipv6') ? 'ospfv3 3' : 'ospf 3'
    if platform == :nexus
      master = [['direct',  'rm_direct'],
                ['lisp',    'rm_lisp'],
                ['static',  'rm_static'],
                ['eigrp 1', 'rm_eigrp'],
                ['isis 2',  'rm_isis'],
                [ospf,      'rm_ospf'],
                ['rip 4',   'rm_rip']]
    elsif platform == :ios_xr
      config('route-policy my_policy', 'end')
      master = [['connected', 'my_policy'],
                ['eigrp 1',   'my_policy'],
                [ospf,        'my_policy'],
                ['static',    'my_policy']]
      master.push(['isis abc', 'my_policy']) if dbg.include? 'default'
    end
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
    config('route-policy my_policy_2', 'end')
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
    %w(my_policy my_policy_2).each do |policy|
      config("no route-policy #{policy}")
    end if platform == :ios_xr
  end

  ##
  ## common utilities
  ##

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
end
