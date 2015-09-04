#!/usr/bin/env ruby
# RouterBgpNbrAF Unit Tests
#
# August 2015 Chris Van Heuveln
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
require File.expand_path("../../lib/cisco_node_utils/bgp_neighbor", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/bgp_nbr_af", __FILE__)

class TestRouterBgpNbrAF < CiscoTestCase
  @@reset_feat = true

  def setup
    super
    if @@reset_feat
      @device.cmd("conf t ; no feature bgp ; feature bgp ; end")
      @@reset_feat = false
    else
      # Just ensure that feature is enabled
      @device.cmd("conf t ; feature bgp ; end")
    end
  end

  def clean_af(af_args, ebgp = true)
    # Most tests only need an address-family cleanup
    asn, vrf, nbr, af = af_args
    dbg = sprintf("[VRF %s NBR %s AF %s]", vrf, nbr, af.join('/'))

    obj_nbr = RouterBgpNeighbor.new(asn, vrf, nbr, true)
    obj_nbr.remote_as = ebgp ? asn + 1 : asn

    obj_af = RouterBgpNbrAF.new(asn, vrf, nbr, af, true)

    # clean up address-family only
    obj_af.destroy
    obj_af.create
    [obj_af, dbg]
  end

  # def test_foo
  #   af, dbg = clean_af([2, 'red', '1.1.1.1', %w(ipv4 unicast)])
  #   foo(af, dbg)
  # end

  # AF test matrix
  @@matrix = {
    # 1 => [1, 'default', '10:1::1', %w(ipv4 multicast)], # UNSUPPORTED
    2 => [1, 'default', '10:1::1', %w(ipv4 unicast)],
    3 => [1, 'default', '10:1::1', %w(ipv6 multicast)],
    4 => [1, 'default', '10:1::1', %w(ipv6 unicast)],
    5 => [1, 'default', '1.1.1.1', %w(ipv4 multicast)],
    6 => [1, 'default', '1.1.1.1', %w(ipv4 unicast)],
    7 => [1, 'default', '1.1.1.1', %w(ipv6 multicast)],
    8 => [1, 'default', '1.1.1.1', %w(ipv6 unicast)],
    9 => [1, 'aa', '2.2.2.2', %w(ipv4 multicast)],
    10 => [1, 'aa', '2.2.2.2', %w(ipv4 unicast)],
    11 => [1, 'bb', '2.2.2.2', %w(ipv6 multicast)],
    12 => [1, 'bb', '2.2.2.2', %w(ipv6 unicast)],
    # 13 => [1, 'cc', '10:1::2', %w(ipv4 multicast)], # UNSUPPORTED
    14 => [1, 'cc', '10:1::2', %w(ipv4 unicast)],
    15 => [1, 'cc', '10:1::2', %w(ipv6 multicast)],
    16 => [1, 'cc', '10:1::2', %w(ipv6 unicast)],
  }

  # ---------------------------------
  def test_nbr_af_create_destroy
    @device.cmd('conf t ; no feature bgp ; feature bgp')

    # Creates
    obj = {}
    @@matrix.each do |k, v|
      asn, vrf, nbr, af = v
      dbg = sprintf('[VRF %s NBR %s AF %s]', vrf, nbr, af)
      obj[k] = RouterBgpNbrAF.new(asn, vrf, nbr, af, true)
      afs = RouterBgpNbrAF.afs
      assert(afs[asn][vrf][nbr].key?(af),
             "#{dbg} Failed to create AF")
    end

    # Destroys
    @@matrix.each do |k, v|
      asn, vrf, nbr, af = v
      dbg = sprintf('[VRF %s NBR %s AF %s]', vrf, nbr, af)
      obj[k].destroy
      afs = RouterBgpNbrAF.afs
      refute(afs[asn][vrf][nbr].key?(af),
             "#{dbg} Failed to destroy AF")
    end
  end

  # ---------------------------------
  def test_nbrs_with_masks
    @device.cmd('conf t ; no feature bgp ; feature bgp')

    # Creates
    obj = {}
    @@matrix.each do |k, v|
      asn, vrf, nbr, af = v
      nbr += (nbr[/:/]) ? '/64' : '/16'
      dbg = sprintf("[VRF %s NBR %s AF %s]", vrf, nbr, af.join('/'))
      obj[k] = RouterBgpNbrAF.new(asn, vrf, nbr, af, true)
      nbr_munged = RouterBgpNeighbor.nbr_munge(nbr)
      afs = RouterBgpNbrAF.afs
      assert(afs[asn][vrf][nbr_munged].key?(af),
             "#{dbg} Failed to create AF")
    end

    # Destroys
    @@matrix.each do |k, v|
      asn, vrf, nbr, af = v
      nbr += (nbr[/:/]) ? '/64' : '/16'
      dbg = sprintf('[VRF %s NBR %s AF %s]', vrf, nbr, af.join('/'))
      obj[k].destroy
      nbr_munged = RouterBgpNeighbor.nbr_munge(nbr)
      afs = RouterBgpNbrAF.afs
      refute(afs[asn][vrf][nbr_munged].key?(af),
             "#{dbg} Failed to destroy AF")
    end
    @@reset_feat = true
  end

  # ---------------------------------
  def test_props_bool
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      props_bool(af, dbg)
    end
  end

  def props_bool(af, dbg)
    # These properties have simple boolean states. As such we can use a common
    # set of tests to validate each property.
    props = [
      :as_override, :disable_peer_as_check,
      :next_hop_self, :next_hop_third_party,
      :suppress_inactive,
    ]

    props.each { |k|
      # Call setter.
      af.send("#{k}=", false)

      # Validate with getter
      refute(af.send(k),
             "Test 1. #{dbg} [#{k}=] did not set false")

      af.send("#{k}=", true)
      assert(af.send(k),
             "Test 2. #{dbg} [#{k}=] did not set true")

      # Set to default
      def_val = af.send("default_#{k}")
      af.send("#{k}=", def_val)
      assert_equal(def_val, af.send(k),
                   "Test 3. #{dbg} [#{k}=] did not set to default")
    }
  end

  # ---------------------------------
  def test_props_string
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      props_string(af, dbg)
    end
  end

  def props_string(af, dbg)
    # These properties have a common string value (route-map), allowing them
    # to use a common set of tests to validate each property.
    props = {
      :filter_list_in => "filt-in-name",
      :filter_list_out => "filt-out-name",
      :unsuppress_map => "unsupp-map-name",
    }

    props.each do |k, v|
      # Call setter.
      af.send("#{k}=", v)

      # Validate with getter
      assert_equal(v, af.send(k),
                   "Test 1. #{dbg} [#{k}=] did not set string '#{v}'")

      af.send("#{k}=", v.reverse!)
      assert_equal(v, af.send(k),
                   "Test 2. #{dbg} [#{k}=] did not set string '#{v}'")

      # Set to default
      af.send("#{k}=", af.send("default_#{k}"))
      assert_empty(af.send(k),
                   "Test 3. #{dbg} [#{k}=] did not set default [default_#{k}]")
    end
  end

  # ---------------------------------
  def test_advertise_map
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      advertise_map(af, dbg)
    end
  end

  def advertise_map(af, dbg)
    %w(advertise_map_exist advertise_map_non_exist).each do |k|
      v = %w(foo bar)
      af.send("#{k}=", v)
      assert_equal(v, af.send(k),
                   "Test 1. #{dbg} [#{k}=] did not set strings '#{v}'")

      # Change to new strings
      v = %w(baz inga)
      af.send("#{k}=", v)
      assert_equal(v, af.send(k),
                   "Test 2. #{dbg} [#{k}=] did not set strings '#{v}'")

      # Set to default
      af.send("#{k}=", af.send("default_#{k}"))
      assert_empty(af.send(k),
                   "Test 3. #{dbg} [#{k}] did not set to default " +
                   "'[default_#{k}]'")
    end
  end

  # ---------------------------------
  def test_allowas_in
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      allowas_in(af, dbg)
    end
  end

  def allowas_in(af, dbg)
    af.allowas_in_set(true)
    assert(af.allowas_in,
           "Test 1. #{dbg} Failed to set state to True")

    # Test true with value
    af.allowas_in_set(true, 5)
    assert_equal(5, af.allowas_in_max,
                 "Test 2. #{dbg} Failed to set True with Value")

    # Test false with value
    af.allowas_in_set(false)
    refute(af.allowas_in,
           "Test 3. #{dbg} Failed to set state to False")

    # Test true with value, from false
    af.allowas_in_set(true, 4)
    assert_equal(4, af.allowas_in_max,
                 "Test 4. #{dbg} Failed to set True with Value, " +
                 "from false state")

    # Test default_state
    af.allowas_in_set(af.default_allowas_in)
    refute(af.allowas_in,
           "Test 5. #{dbg} Failed to set state to default")

    # Test true with value set to default
    af.allowas_in_set(true, af.default_allowas_in_max)
    assert_equal(af.default_allowas_in_max, af.allowas_in_max,
                 "Test 6. #{dbg} Failed to set True with default Value")
  end

  # ---------------------------------
  def test_cap_add_paths
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      cap_add_paths(af, dbg)
    end
  end

  def cap_add_paths(af, dbg)
    %w(cap_add_paths_receive cap_add_paths_send).each do |k|
      # Test basic true
      af.send("#{k}_set", true)
      assert(af.send(k),
             "Test 1. #{dbg} [#{k}_set] failed to set state to True")

      # Test true with disable, from true
      af.send("#{k}_set", true, true)
      assert(af.send("#{k}_disable"),
             "Test 2. #{dbg} [#{k}_set] Failed to set True with disable")

      # Test false while disabled
      af.send("#{k}_set", false)
      refute(af.send(k),
             "Test 3. #{dbg} [#{k}_set] Failed to set False while disabled")

      # Test true with disable, from false
      af.send("#{k}_set", true, true)
      assert(af.send("#{k}_disable"),
             "Test 4. #{dbg} [#{k}_set] Failed to set True with disable " +
             "from false")

      # Test default_state
      def_state = af.send("default_#{k}")
      af.send("#{k}_set", def_state)
      assert_equal(def_state, af.send(k),
                   "Test 5. #{dbg} [#{k}_set] Failed to set state to default")

      # Test true with default disable state
      def_disable = af.send("default_#{k}_disable")
      af.send("#{k}_set", true, def_disable)
      assert_equal(def_disable, af.send("#{k}_disable"),
                   "Test 6. #{dbg} [#{k}_set] Failed to set True with " +
                   "default disable")

      # Test false with true disable state
      af.send("#{k}_set", false, true)
      refute(af.send("#{k}_disable"),
             "Test 7. #{dbg} [#{k}_set] Failed to set False with True " +
             "disable state")
    end
  end

  # ---------------------------------
  def test_default_originate
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      default_originate(af, dbg)
    end
  end

  def default_originate(af, dbg)
    # Test basic true
    af.default_originate_set(true)
    assert(af.default_originate,
           "Test 1. #{dbg} Failed to set state to True")

    # Test true with route-map
    af.default_originate_set(true, "foo_bar")
    assert_equal("foo_bar", af.default_originate_route_map,
                 "Test 2. #{dbg} Failed to set True with Route-map")

    # Test false with route-map
    af.default_originate_set(false)
    refute(af.default_originate,
           "Test 3. #{dbg} Failed to set state to False")

    # Test true with route-map, from false
    af.default_originate_set(true, "baz_inga")
    assert_equal("baz_inga", af.default_originate_route_map,
                 "Test 4. #{dbg} Failed to set True with Route-map, " \
                 "from false state")

    # Test default route-map, from true
    af.default_originate_set(true, af.default_default_originate_route_map)
    refute(af.default_originate_route_map,
           "Test 5. #{dbg} Failed to set default route-map from existing")

    # Test default_state
    af.default_originate_set(af.default_default_originate)
    refute(af.default_originate,
           "Test 6. #{dbg} Failed to set state to default")

  end

  # ---------------------------------
  def test_max_prefix
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      max_prefix(af, dbg)
    end
  end

  def max_prefix(af, dbg)
    limit = 100
    af.max_prefix_set(limit)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 1. #{dbg} Failed to set limit to '#{limit}'")

    limit, threshold, = 99, 49
    af.max_prefix_set(limit, threshold)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 2a. #{dbg} Failed to set limit to '#{limit}'")
    assert_equal(threshold, af.max_prefix_threshold,
                 "Test 2b. #{dbg} Failed to set threshold to '#{threshold}'")

    limit, threshold, interval = 98, 48, 28
    af.max_prefix_set(limit, threshold, interval)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 3a. #{dbg} Failed to set limit to '#{limit}'")
    assert_equal(threshold, af.max_prefix_threshold,
                 "Test 3b. #{dbg} Failed to set threshold to '#{threshold}'")
    assert_equal(interval, af.max_prefix_interval,
                 "Test 3c. #{dbg} Failed to set interval to '#{interval}'")

    limit, threshold, warning = 97, nil, true
    af.max_prefix_set(limit, threshold, warning)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 4a. #{dbg} Failed to set limit to '#{limit}'")
    assert_equal(threshold, af.max_prefix_threshold,
                 "Test 4b. #{dbg} Failed to set threshold to '#{threshold}'")
    assert_equal(warning, af.max_prefix_warning,
                 "Test 4c. #{dbg} Failed to set warning to '#{warning}'")

    limit, threshold, interval = 96, nil, 26
    af.max_prefix_set(limit, threshold, interval)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 5a. #{dbg} Failed to set limit to '#{limit}'")
    assert_equal(threshold, af.max_prefix_threshold,
                 "Test 5b. #{dbg} Failed to set threshold to '#{threshold}'")
    assert_equal(interval, af.max_prefix_interval,
                 "Test 5c. #{dbg} Failed to set interval to '#{interval}'")

    limit, threshold, warning = 95, 45, true
    af.max_prefix_set(limit, threshold, warning)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 6a. #{dbg} Failed to set limit to '#{limit}'")
    assert_equal(threshold, af.max_prefix_threshold,
                 "Test 6b. #{dbg} Failed to set threshold to '#{threshold}'")
    assert_equal(warning, af.max_prefix_warning,
                 "Test 6c. #{dbg} Failed to set warning to '#{warning}'")

    af.max_prefix_set(af.default_max_prefix_limit)
    refute(af.max_prefix_limit,
           "Test 7. #{dbg} Failed to remove maximum_prefix")

    limit = 94
    threshold = af.default_max_prefix_threshold
    interval = af.default_max_prefix_interval
    af.max_prefix_set(limit, threshold, interval)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 8a. #{dbg} Failed to set limit to '#{limit}'")
    assert_equal(threshold, af.max_prefix_threshold,
                 "Test 8b. #{dbg} Failed to set threshold to '#{threshold}'")
    assert_equal(interval, af.max_prefix_interval,
                 "Test 8c. #{dbg} Failed to set interval to '#{interval}'")

    limit = 93
    threshold = af.default_max_prefix_threshold
    warning = af.default_max_prefix_warning
    af.max_prefix_set(limit, threshold, warning)
    assert_equal(limit, af.max_prefix_limit,
                 "Test 9a. #{dbg} Failed to set limit to '#{limit}'")
    assert_equal(threshold, af.max_prefix_threshold,
                 "Test 9b. #{dbg} Failed to set threshold to '#{threshold}'")
    assert_equal(warning, af.max_prefix_warning,
                 "Test 9c. #{dbg} Failed to set warning to '#{warning}'")

    af.max_prefix_set(nil)
    refute(af.max_prefix_limit,
           "Test 10. #{dbg} Failed to remove maximum_prefix")
  end

  # ---------------------------------
  def test_route_reflector_client
    @@matrix.values.each do |af_args|
      # clean_af needs false since route_reflector_client is ibgp only
      af, dbg = clean_af(af_args, false)
      route_reflector_client(af, dbg)
    end
  end

  def route_reflector_client(af, dbg)
    # iBGP only
    af.route_reflector_client = false
    refute(af.route_reflector_client,
           "Test 1. #{dbg} Did not set false")

    af.route_reflector_client = true
    assert(af.route_reflector_client,
           "Test 2. #{dbg} Did not set true")

    def_val = af.default_route_reflector_client
    af.route_reflector_client = def_val
    assert_equal(def_val, af.route_reflector_client,
                 "Test 3. #{dbg} Did not set to default")
  end

  # ---------------------------------
  def test_send_community
    # iBGP only, do extra cleanup
    @device.cmd('conf t ; no feature bgp ; feature bgp')
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      send_community(af, dbg)
    end
    @@reset_feat = true
  end

  def send_community(af, dbg)
    v = "both"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 1a. #{dbg} Failed to set '#{v}' from None")
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 1b. #{dbg} Failed to set '#{v}' from 'both'")
    v = "extended"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 2a. #{dbg} Failed to set '#{v}' from 'both'")
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 2b. #{dbg} Failed to set '#{v}' from 'extended'")
    v = "standard"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 3a. #{dbg} Failed to set '#{v}' from 'extended'")
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 3b. #{dbg} Failed to set '#{v}' from 'standard'")

    v = "extended"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 4. #{dbg} Failed to set '#{v}' from 'standard'")

    v = "both"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 5. #{dbg} Failed to set '#{v}' from 'extended'")

    v = "standard"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 6. #{dbg} Failed to set '#{v}' from 'both'")
    v = "both"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 7. #{dbg} Failed to set '#{v}' from 'standard'")

    v = "none"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 8. #{dbg} Failed to remove send-community")

    v = "both"
    af.send_community = v
    assert_equal(v, af.send_community,
                 "Test 9. #{dbg} Failed to set '#{v}' from None")

    v = af.default_send_community
    af.send_community = af.default_send_community
    assert_equal(v, af.send_community,
                 "Test 10. #{dbg} Failed to set state to default")
  end

  # ---------------------------------
  def test_soft_reconfiguration_in
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      soft_reconfiguration_in(af, dbg)
    end
  end

  def soft_reconfiguration_in(af, dbg)
    # Test basic true
    af.soft_reconfiguration_in_set(true)
    assert(af.soft_reconfiguration_in,
           "Test 1. #{dbg} Failed to set True")

    # Test true with always
    af.soft_reconfiguration_in_set(true, true)
    assert(af.soft_reconfiguration_in_always,
           "Test 2. #{dbg} Failed to set True with Always")

    # Test false with always
    af.soft_reconfiguration_in_set(false)
    refute(af.soft_reconfiguration_in,
           "Test 3. #{dbg} Failed to set False")

    # Test true with always, from false
    af.soft_reconfiguration_in_set(true, true)
    assert(af.soft_reconfiguration_in_always,
           "Test 4. #{dbg} Failed to set True with Always, from false")

    # Test default_state
    af.soft_reconfiguration_in_set(af.default_soft_reconfiguration_in)
    refute(af.soft_reconfiguration_in,
           "Test 5. #{dbg} Failed to set to default")

    # Test true with Always set to default
    af.soft_reconfiguration_in_set(true,
                                   af.default_soft_reconfiguration_in_always)
    refute(af.soft_reconfiguration_in_always,
           "Test 6. #{dbg} Failed to set True with default Always")
  end

  # ---------------------------------
  def test_soo
    @@matrix.values.each do |af_args|
      af, dbg = clean_af(af_args)
      soo(af, dbg)
    end
  end

  def soo(af, dbg)
    val = "1.1.1.1:1"

    if dbg.include?('default')
      assert_raises(CliError, "Test 1. #{dbg}[soo=] did not raise CliError") {
        af.soo = val
      }
      # SOO is only allowed in non-default VRF
      return
    end

    # Set initial
    af.soo = val
    assert_equal(val, af.soo,
                 "Test 2. #{dbg} Failed to set '#{val}'")

    # Change to new string
    val = "2:2"
    af.soo = val
    assert_equal(val, af.soo,
                 "Test 3. #{dbg} Failed to change to '#{val}'")

    # Set to default
    val = af.default_soo
    af.soo = val
    assert_empty(af.soo,
                 "Test 4. #{dbg} Failed to set default '#{val}'")
  end
end
