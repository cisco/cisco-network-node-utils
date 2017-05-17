#!/usr/bin/env ruby
# RouterBgp Unit Tests
#
# Mike Wiebe, June, 2015
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

# Temporary debug helper. Not for production and not to replace Cisco debugging.
def debug_bgp
  s = @device.cmd('show running-config router bgp')
  caller_locations(1, 1).first.tap do |loc|
    puts "\nDEBUG BGP: #{__FILE__}:#{loc.path}:#{loc.lineno}:\n#{s}"
  end
end

def create_bgp_vrf(asnum, vrf)
  if platform == :nexus
    bgp = RouterBgp.new(asnum, vrf)
  else
    # IOS XR requires 'rd <id>' for any created VRF.
    # But 'rd' requires a global router id. From a puppet p.o.v
    # this is fine; the user is required to add a router-id to
    # their manifest. For the minitest fudge this by calling
    # RouterBgp.new twice. Once to create the BGP process,
    # add a router-id, then call it again to create the VRF,
    # and add a VRF level router-id (which is needed to make SYSDB
    # behave).
    bgp = RouterBgp.new(asnum)
    bgp.router_id = '1.2.3.4'
    bgp = RouterBgp.new(asnum, vrf)
    bgp.router_id = '4.5.6.7'
  end
  bgp
end

def setup_default
  @asnum = 55
  @vrf = 'default'
  RouterBgp.new(@asnum)
end

def setup_vrf
  @asnum = 99
  @vrf = 'yamllll'
  create_bgp_vrf(@asnum, @vrf)
end

def newer_image_version?
  new = true
  new = false if Utils.image_version?(/7.0.3.I2|I3|I4/) ||
                 node.product_id[/(N5|N6|N7|N9.*-F)/]
  new = true if Utils.image_version?(/8.0|8.1/)
  new
end

# TestRouterBgp - Minitest for RouterBgp class
class TestRouterBgp < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_bgps if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    remove_all_bgps
    super
  end

  def get_routerbgp_match_line(as_number, vrf='default')
    if platform == :ios_xr
      s = @device.cmd('show running-config router bgp')
    else
      s = @device.cmd("show run | section '^router bgp .*'")
    end
    if vrf == 'default'
      line = /router bgp\s#{as_number}/.match(s)
    else
      line = /vrf #{vrf}/.match(s)
    end
    line
  end

  def test_collection_empty
    if platform == :ios_xr
      config('no router bgp')
    else
      config('no feature bgp')
    end
    node.cache_flush
    routers = RouterBgp.routers
    assert_empty(routers, 'RouterBgp collection is not empty')
  end

  def test_collection_not_empty
    if platform == :nexus
      config('feature bgp',
             'router bgp 55',
             'vrf blue',
             'vrf red',
             'vrf white')
    else
      config('router bgp 55',
             'bgp router-id 1.2.3.4',
             'vrf blue',
             'bgp router-id 4.5.6.7',
             'rd auto',
             'vrf red',
             'bgp router-id 4.5.6.7',
             'rd auto',
             'vrf white',
             'bgp router-id 4.5.6.7',
             'rd auto')
    end
    routers = RouterBgp.routers
    refute_empty(routers, 'RouterBgp collection is empty')
    # validate the collection
    routers.each do |asnum, vrfs|
      line = get_routerbgp_match_line(asnum)
      refute_nil(line)
      vrfs.each_key do |name|
        unless name == 'default'
          line = get_routerbgp_match_line(asnum, name)
          refute_nil(line)
        end
      end
    end
  end

  def test_asnum_invalid
    ['', 'Fifty_Five'].each do |test|
      assert_raises(ArgumentError, "#{test} not a valid asn") do
        RouterBgp.new(test)
      end
    end
  end

  def test_vrf_invalid
    ['', 55].each do |test|
      assert_raises(ArgumentError, "#{test} not a valid vrf name") do
        RouterBgp.new(88, test)
      end
    end
  end

  def test_create_vrfname_zero_length
    asnum = 55
    assert_raises(ArgumentError) do
      RouterBgp.new(asnum, '')
    end
  end

  def test_create_valid
    bgp = setup_default
    line = get_routerbgp_match_line(@asnum)
    refute_nil(line, "Error: 'router bgp #{@asnum}' not configured")
    bgp.destroy

    vrf = 'wolfpack'
    bgp = create_bgp_vrf(55, vrf)
    line = get_routerbgp_match_line(@asnum, vrf)
    refute_nil(line,
               "Error: 'router bgp #{@asnum}' vrf '#{vrf}' not configured")
    bgp.destroy
  end

  def test_process_initialized
    return if validate_property_excluded?('bgp', 'process_initialized')

    # Cleanup may be slow on some platforms; make sure it's really dead
    bgp = RouterBgp.new('55', 'default', false)
    if bgp.process_initialized?
      sleep 4
      node.cache_flush
    end
    refute(bgp.process_initialized?, 'bgp should not be initialized')

    bgp = RouterBgp.new('55', 'default')
    bgp.wait_for_process_initialized unless bgp.process_initialized?
    assert(bgp.process_initialized?, 'bgp should be initialized')
  end

  def wait_for_process_kill(bgp)
    return unless node.product_id[/N(5|6)/]
    # Hack for slow-start platforms which can also be slow-to-die.
    # Tests that involve many quick process-start / process-stop cycles
    # are prone to failure without this delay.
    4.times do
      return unless bgp.process_initialized?
      sleep 1
      node.cache_flush
    end
    fail "#{bgp} :: process is still running"
  end

  def test_valid_asn
    [1, 4_294_967_295, '55', '1.0', '1.65535', '65535.0', '65535.65535'
    ].each do |asn|
      b = RouterBgp.new(asn)
      assert_equal(asn.to_s, RouterBgp.routers.keys[0].to_s)
      b.destroy
      wait_for_process_kill(b)
    end
  end

  def test_destroy
    bgp = setup_default
    line = get_routerbgp_match_line(@asnum)
    refute_nil(line, "Error: 'router bgp #{@asnum}' not configured")
    bgp.destroy

    if platform == :ios_xr
      command = 'show run router bgp'
      pattern = /"router bgp"/
    else
      command = 'show run all | no-more'
      pattern = /"feature bgp"/
    end

    refute_show_match(
      command: command, pattern: pattern,
      msg: "Error: 'router bgp' still configured")
  end

  def test_create_invalid_multiple
    asnum = 55
    bgp1 = RouterBgp.new(asnum)
    line = get_routerbgp_match_line(asnum)
    refute_nil(line, "Error: 'router bgp #{asnum}' not configured")

    # Only one bgp instance supported so try to create another.
    assert_raises(CliError) do
      bgp2 = RouterBgp.new(88)
      bgp2.destroy unless bgp2.nil?
    end
    bgp1.destroy
  end

  def test_asnum_dot
    asnum = 65_540
    bgp = RouterBgp.new(asnum)
    assert_equal(asnum.to_s, bgp.asnum, 'Error: router asnum incorrect')

    # Create a new object with the same ASN value but using AS_DOT notation
    assert_raises(CliError) do
      RouterBgp.new('1.4')
    end
  end

  def test_nsr
    nsr(setup_default)
    nsr(setup_vrf)
  end

  def nsr(bgp)
    if (platform == :nexus) || (platform == :ios_xr && !@vrf[/default/])
      if platform == :nexus
        assert_nil(bgp.default_nsr,
                   'default bgp nsr should be nil on Nexus')
        assert_nil(bgp.nsr,
                   'bgp nsr should be nil on Nexus')
      else
        assert_nil(bgp.default_nsr,
                   'default bgp nsr should return nil on XR with non-default' \
                   ' vrf')
        assert_nil(bgp.nsr,
                   'bgp nsr should return nil on XR with non-default vrf')
      end
      assert_raises(Cisco::UnsupportedError) do
        bgp.nsr = true
      end
    else
      assert_equal(bgp.nsr, bgp.default_nsr)
      bgp.nsr = true
      assert(bgp.nsr,
             'bgp nsr should be enabled')
      bgp.nsr = false
      refute(bgp.nsr,
             'bgp nsr should be disabled')
    end
    bgp.destroy
  end

  def test_bestpath_default
    bestpath(setup_default)
  end

  def test_bestpath_vrf
    bestpath(setup_vrf)
  end

  def bestpath(bgp)
    bgp.bestpath_always_compare_med = true
    assert(bgp.bestpath_always_compare_med,
           'bgp bestpath_always_compare_med should be enabled')
    bgp.bestpath_aspath_multipath_relax = true
    assert(bgp.bestpath_aspath_multipath_relax,
           'bgp bestpath_aspath_multipath_relax should be enabled')
    bgp.bestpath_compare_routerid = true
    assert(bgp.bestpath_compare_routerid,
           'bgp bestpath_compare_routerid should be enabled')
    bgp.bestpath_cost_community_ignore = true
    assert(bgp.bestpath_cost_community_ignore,
           'bgp bestpath_cost_community_ignore should be enabled')
    if platform == :ios_xr && !@vrf[/default/]
      assert_raises(Cisco::UnsupportedError) do
        bgp.bestpath_med_confed = true
      end
    else
      bgp.bestpath_med_confed = true
      assert(bgp.bestpath_med_confed,
             'bgp bestpath_med_confed should be enabled')
    end
    bgp.bestpath_med_missing_as_worst = true
    assert(bgp.bestpath_med_missing_as_worst,
           'bgp bestpath_med_missing_as_worst should be enabled')
    if platform == :nexus
      bgp.bestpath_med_non_deterministic = true
      assert(bgp.bestpath_med_non_deterministic,
             'bgp bestpath_med_non_deterministic should be enabled')
    else
      assert_raises(Cisco::UnsupportedError) do
        bgp.bestpath_med_non_deterministic = true
      end
    end
    bgp.bestpath_always_compare_med = false
    refute(bgp.bestpath_always_compare_med,
           'bgp bestpath_always_compare_med should be disabled')
    bgp.bestpath_aspath_multipath_relax = false
    refute(bgp.bestpath_aspath_multipath_relax,
           'bgp bestpath_aspath_multipath_relax should be disabled')
    bgp.bestpath_compare_routerid = false
    refute(bgp.bestpath_compare_routerid,
           'bgp bestpath_compare_routerid should be disabled')
    bgp.bestpath_cost_community_ignore = false
    refute(bgp.bestpath_cost_community_ignore,
           'bgp bestpath_cost_community_ignore should be disabled')
    unless platform == :ios_xr && !@vrf[/default/]
      bgp.bestpath_med_confed = false
      refute(bgp.bestpath_med_confed,
             'bgp bestpath_med_confed should be disabled')
    end
    bgp.bestpath_med_missing_as_worst = false
    refute(bgp.bestpath_med_missing_as_worst,
           'bgp bestpath_med_missing_as_worst should be disabled')
    if platform == :nexus
      bgp.bestpath_med_non_deterministic = false
      refute(bgp.bestpath_med_non_deterministic,
             'bgp bestpath_med_non_deterministic should be disabled')
    else
      assert_raises(Cisco::UnsupportedError) do
        bgp.bestpath_med_non_deterministic = false
      end
    end
    bgp.destroy
  end

  def test_bestpath_not_configured_default
    bestpath_not_configured(setup_default)
  end

  def test_bestpath_not_configured_vrf
    bestpath_not_configured(setup_vrf)
  end

  def bestpath_not_configured(bgp)
    refute(bgp.bestpath_always_compare_med,
           'bgp bestpath_always_compare_med should *NOT* be enabled')
    refute(bgp.bestpath_aspath_multipath_relax,
           'bgp bestpath_aspath_multipath_relax should *NOT* be enabled')
    refute(bgp.bestpath_compare_routerid,
           'bgp bestpath_compare_routerid should be *NOT* enabled')
    refute(bgp.bestpath_cost_community_ignore,
           'bgp bestpath_cost_community_ignore should *NOT* be enabled')
    refute(bgp.bestpath_med_confed,
           'bgp bestpath_med_confed should *NOT* be enabled')
    refute(bgp.bestpath_med_missing_as_worst,
           'bgp bestpath_med_missing_as_worst should *NOT* be enabled')
    if platform == :nexus
      refute(bgp.bestpath_med_non_deterministic,
             'bgp bestpath_med_non_deterministic should *NOT* be enabled')
    else
      assert_nil(bgp.bestpath_med_non_deterministic,
                 'bgp bestpath_med_non_deterministic should *NOT* be supported')
    end
    bgp.destroy
  end

  def test_default_bestpath
    bgp = setup_default
    refute(bgp.default_bestpath_always_compare_med,
           'default value for bestpath_always_compare_med should be false')
    refute(bgp.default_bestpath_aspath_multipath_relax,
           'default value for bestpath_aspath_multipath_relax should be false')
    refute(bgp.default_bestpath_compare_routerid,
           'default value for bestpath_compare_routerid should be false')
    refute(bgp.default_bestpath_cost_community_ignore,
           'default value for bestpath_cost_community_ignore should be false')
    refute(bgp.default_bestpath_med_confed,
           'default value for bestpath_med_confed should be false')
    refute(bgp.default_bestpath_med_missing_as_worst,
           'default value for bestpath_med_missing_as_worst should be false')
    if platform == :nexus
      refute(bgp.default_bestpath_med_non_deterministic,
             'default value for bestpath_med_non_deterministic should be false')
    else
      assert_nil(bgp.default_bestpath_med_non_deterministic,
                 'bgp default_bestpath_med_non_deterministic should ' \
                 '*NOT* be supported')
    end
    bgp.destroy
  end

  def test_cluster_id_default
    cluster_id(setup_default)
  end

  def test_cluster_id_vrf
    cluster_id(setup_vrf)
  end

  def cluster_id(bgp)
    if platform == :ios_xr && @vrf != 'default'
      # XR does not support this under a VRF, so test the getter and setter
      assert_nil(bgp.cluster_id,
                 'cluster_id should return nil on XR with non-default vrf')
      assert_raises(Cisco::UnsupportedError) do
        bgp.cluster_id = 34
      end
      bgp.destroy
      return
    end
    bgp.cluster_id = 34
    assert_equal('34', bgp.cluster_id,
                 "bgp cluster_id should be set to '34'")
    bgp.cluster_id = '1.2.3.4'
    assert_equal('1.2.3.4', bgp.cluster_id,
                 "bgp cluster_id should be set to '1.2.3.4'")
    bgp.cluster_id = ''
    assert_empty(bgp.cluster_id,
                 'bgp cluster_id should *NOT* be configured')
    bgp.destroy
  end

  def test_cluster_id_not_configured
    bgp = setup_default
    assert_empty(bgp.cluster_id,
                 'bgp cluster_id should *NOT* be configured')
    bgp.destroy
  end

  def test_default_cluster_id
    bgp = setup_default
    assert_empty(bgp.default_cluster_id,
                 'bgp cluster_id default value should be empty')
    bgp.destroy
  end

  def test_disable_policy_batching
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.disable_policy_batching)
      assert_raises(Cisco::UnsupportedError) do
        bgp.disable_policy_batching = true
      end
    else
      bgp.disable_policy_batching = true
      assert(bgp.disable_policy_batching,
             'bgp disable-policy-batching should be enabled')
      bgp.disable_policy_batching = false
      refute(bgp.disable_policy_batching,
             'bgp disable-policy-batching should be disabled')
    end
    bgp.destroy
  end

  def test_default_disable_policy_batching
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.disable_policy_batching)
      assert_nil(bgp.default_disable_policy_batching)
    else
      refute(bgp.disable_policy_batching,
             'bgp disable-policy-batching value should be false')
    end
    bgp.destroy
  end

  def test_disable_policy_batching_ipv4
    if platform == :ios_xr || node.product_id[/N(5|6)/]
      b = RouterBgp.new(1)
      assert_nil(b.disable_policy_batching_ipv4)
      assert_nil(b.default_disable_policy_batching_ipv4)
      assert_raises(Cisco::UnsupportedError) do
        b.disable_policy_batching_ipv4 = 'xx'
      end
      return
    end
    skip_incompat_version?('bgp', 'disable_policy_batching_ipv4')
    bgp = setup_default
    default = bgp.default_disable_policy_batching_ipv4
    assert_equal(default, bgp.disable_policy_batching_ipv4,
                 'bgp disable_policy_batching_ipv4 not set to default')

    bgp.disable_policy_batching_ipv4 = 'xx'
    assert_equal('xx', bgp.disable_policy_batching_ipv4,
                 "bgp disable_policy_batching_ipv4 should be set to 'xx'")
    bgp.disable_policy_batching_ipv4 = \
      bgp.default_disable_policy_batching_ipv4
    assert_empty(bgp.disable_policy_batching_ipv4,
                 'bgp disable_policy_batching_ipv4 should be empty')

    bgp.disable_policy_batching_ipv4 = default
    assert_equal(default, bgp.disable_policy_batching_ipv4,
                 'bgp disable_policy_batching_ipv4 not set to default')
    bgp.destroy
  end

  def test_disable_policy_batching_ipv6
    if platform == :ios_xr || node.product_id[/N(5|6)/]
      b = RouterBgp.new(1)
      assert_nil(b.disable_policy_batching_ipv6)
      assert_nil(b.default_disable_policy_batching_ipv6)
      assert_raises(Cisco::UnsupportedError) do
        b.disable_policy_batching_ipv6 = 'xx'
      end
      return
    end
    skip_incompat_version?('bgp', 'disable_policy_batching_ipv6')
    bgp = setup_default
    default = bgp.default_disable_policy_batching_ipv6
    assert_equal(default, bgp.disable_policy_batching_ipv6,
                 'bgp disable_policy_batching_ipv6 not set to default')

    bgp.disable_policy_batching_ipv6 = 'xx'
    assert_equal('xx', bgp.disable_policy_batching_ipv6,
                 "bgp disable_policy_batching_ipv6 should be set to 'xx'")
    bgp.disable_policy_batching_ipv6 = \
      bgp.default_disable_policy_batching_ipv6
    assert_empty(bgp.disable_policy_batching_ipv6,
                 'bgp disable_policy_batching_ipv6 should be empty')

    bgp.disable_policy_batching_ipv6 = default
    assert_equal(default, bgp.disable_policy_batching_ipv6,
                 'bgp disable_policy_batching_ipv6 not set to default')
    bgp.destroy
  end

  def test_enforce_first_as
    bgp = setup_default
    if platform == :ios_xr
      @default_show_command = 'show running-config router bgp 55'
      @default_output_pattern = /bgp enforce-first-as disable/
    else
      @default_show_command = 'show run bgp all'
      @default_output_pattern = /no enforce-first-as/
    end
    bgp.enforce_first_as = false
    refute(bgp.enforce_first_as)
    assert_show_match(msg: 'enforce-first-as should be disabled')

    bgp.enforce_first_as = true
    assert(bgp.enforce_first_as)
    refute_show_match(msg: 'enforce-first-as should be enabled')

    bgp.destroy
  end

  def test_default_enforce_first_as
    bgp = setup_default
    assert_equal(bgp.default_enforce_first_as,
                 bgp.enforce_first_as,
                 'bgp enforce-first-as default value is incorrect')
    bgp.destroy
  end

  def test_event_history_cli
    bgp = setup_default
    if validate_property_excluded?('bgp', 'event_history_cli')
      assert_nil(bgp.event_history_cli)
      assert_raises(Cisco::UnsupportedError) do
        bgp.event_history_cli = 'true'
      end
      return
    end
    assert_equal(bgp.default_event_history_cli, bgp.event_history_cli)
    bgp.event_history_cli = 'true'
    assert_equal(bgp.default_event_history_cli, bgp.event_history_cli)
    bgp.event_history_cli = 'false'
    assert_equal('false', bgp.event_history_cli)
    bgp.event_history_cli = 'size_small'
    assert_equal('size_small', bgp.event_history_cli)
    bgp.event_history_cli = 'size_large'
    assert_equal('size_large', bgp.event_history_cli)
    bgp.event_history_cli = 'size_medium'
    assert_equal('size_medium', bgp.event_history_cli)
    bgp.event_history_cli = 'size_disable'
    if newer_image_version?
      assert_equal('false', bgp.event_history_cli)
    else
      assert_equal('size_disable', bgp.event_history_cli)
    end
    bgp.event_history_cli = '100000'
    assert_equal('100000', bgp.event_history_cli)
    bgp.event_history_cli = bgp.default_event_history_cli
    assert_equal(bgp.default_event_history_cli, bgp.event_history_cli)
  end

  def test_event_history_detail
    bgp = setup_default
    if validate_property_excluded?('bgp', 'event_history_detail')
      assert_nil(bgp.event_history_detail)
      assert_raises(Cisco::UnsupportedError) do
        bgp.event_history_detail = 'true'
      end
      return
    end
    assert_equal(bgp.default_event_history_detail, bgp.event_history_detail)
    bgp.event_history_detail = 'true'
    assert_equal('true', bgp.event_history_detail)
    bgp.event_history_detail = 'false'
    assert_equal(bgp.default_event_history_detail, bgp.event_history_detail)
    bgp.event_history_detail = 'size_small'
    assert_equal('size_small', bgp.event_history_detail)
    bgp.event_history_detail = 'size_large'
    assert_equal('size_large', bgp.event_history_detail)
    bgp.event_history_detail = 'size_medium'
    assert_equal('size_medium', bgp.event_history_detail)
    bgp.event_history_detail = 'size_disable'
    if newer_image_version?
      assert_equal('false', bgp.event_history_detail)
    else
      assert_equal('size_disable', bgp.event_history_detail)
    end
    bgp.event_history_detail = '100000'
    assert_equal('100000', bgp.event_history_detail)
    bgp.event_history_detail = bgp.default_event_history_detail
    assert_equal(bgp.default_event_history_detail, bgp.event_history_detail)
  end

  def test_event_history_errors
    bgp = setup_default
    if validate_property_excluded?('bgp', 'event_history_errors')
      assert_nil(bgp.event_history_errors)
      assert_raises(Cisco::UnsupportedError) do
        bgp.event_history_errors = 'true'
      end
      return
    end
    skip('platform not supported for this test') unless newer_image_version?
    assert_equal(bgp.default_event_history_errors, bgp.event_history_errors)
    bgp.event_history_errors = 'true'
    assert_equal(bgp.default_event_history_errors, bgp.event_history_errors)
    bgp.event_history_errors = 'false'
    assert_equal('false', bgp.event_history_errors)
    bgp.event_history_errors = 'size_small'
    assert_equal('size_small', bgp.event_history_errors) unless
      Utils.image_version?(/8.0|8.1/)
    bgp.event_history_errors = 'size_large'
    assert_equal('size_large', bgp.event_history_errors)
    bgp.event_history_errors = 'size_medium'
    assert_equal('size_medium', bgp.event_history_errors)
    bgp.event_history_errors = 'size_disable'
    assert_equal('false', bgp.event_history_errors)
    bgp.event_history_errors = '100000'
    assert_equal('100000', bgp.event_history_errors)
    bgp.event_history_errors = bgp.default_event_history_errors
    assert_equal(bgp.default_event_history_errors, bgp.event_history_errors)
  end

  def test_event_history_events
    bgp = setup_default
    if validate_property_excluded?('bgp', 'event_history_events')
      assert_nil(bgp.event_history_events)
      assert_raises(Cisco::UnsupportedError) do
        bgp.event_history_events = 'true'
      end
      return
    end
    assert_equal(bgp.default_event_history_events, bgp.event_history_events)
    bgp.event_history_events = 'true'
    assert_equal(bgp.default_event_history_events, bgp.event_history_events)
    bgp.event_history_events = 'false'
    assert_equal('false', bgp.event_history_events)
    bgp.event_history_events = 'size_small'
    assert_equal('size_small', bgp.event_history_events)
    bgp.event_history_events = 'size_large'
    assert_equal('size_large', bgp.event_history_events)
    bgp.event_history_events = 'size_medium'
    assert_equal('size_medium', bgp.event_history_events)
    bgp.event_history_events = 'size_disable'
    if newer_image_version?
      assert_equal('false', bgp.event_history_events)
    else
      assert_equal('size_disable', bgp.event_history_events)
    end
    bgp.event_history_events = '100000'
    assert_equal('100000', bgp.event_history_events)
    bgp.event_history_events = bgp.default_event_history_events
    assert_equal(bgp.default_event_history_events, bgp.event_history_events)
  end

  def test_event_history_objstore
    bgp = setup_default
    if validate_property_excluded?('bgp', 'event_history_objstore')
      assert_nil(bgp.event_history_objstore)
      assert_raises(Cisco::UnsupportedError) do
        bgp.event_history_objstore = 'true'
      end
      return
    end
    skip('platform not supported for this test') unless newer_image_version?
    assert_equal(bgp.default_event_history_objstore, bgp.event_history_objstore)
    bgp.event_history_objstore = 'true'
    assert_equal('true', bgp.event_history_objstore)
    bgp.event_history_objstore = 'false'
    assert_equal(bgp.default_event_history_objstore, bgp.event_history_objstore)
    bgp.event_history_objstore = 'size_small'
    assert_equal('size_small', bgp.event_history_objstore)
    bgp.event_history_objstore = 'size_large'
    assert_equal('size_large', bgp.event_history_objstore)
    bgp.event_history_objstore = 'size_medium'
    assert_equal('size_medium', bgp.event_history_objstore)
    bgp.event_history_objstore = 'size_disable'
    assert_equal('false', bgp.event_history_objstore)
    bgp.event_history_objstore = '100000'
    assert_equal('100000', bgp.event_history_objstore)
    bgp.event_history_objstore = bgp.default_event_history_objstore
    assert_equal(bgp.default_event_history_objstore, bgp.event_history_objstore)
  end

  def test_event_history_periodic
    bgp = setup_default
    if validate_property_excluded?('bgp', 'event_history_periodic')
      assert_nil(bgp.event_history_periodic)
      assert_raises(Cisco::UnsupportedError) do
        bgp.event_history_periodic = 'true'
      end
      return
    end
    assert_equal(bgp.default_event_history_periodic,
                 bgp.event_history_periodic)
    bgp.event_history_periodic = 'false'
    assert_equal('false', bgp.event_history_periodic) unless
      Utils.image_version?(/8.0|8.1/)
    bgp.event_history_periodic = 'size_small'
    assert_equal('size_small', bgp.event_history_periodic)
    bgp.event_history_periodic = 'size_large'
    assert_equal('size_large', bgp.event_history_periodic)
    bgp.event_history_periodic = 'size_medium'
    assert_equal('size_medium', bgp.event_history_periodic)
    bgp.event_history_periodic = '100000'
    assert_equal('100000', bgp.event_history_periodic)
    bgp.event_history_periodic = 'size_disable'
    if newer_image_version?
      assert_equal(bgp.default_event_history_periodic,
                   bgp.event_history_periodic)
    else
      assert_equal('size_disable', bgp.event_history_periodic)
    end
    bgp.event_history_periodic = 'true'
    if newer_image_version?
      assert_equal('true', bgp.event_history_periodic) unless
        Utils.image_version?(/8.0|8.1/)
    else
      assert_equal(bgp.default_event_history_periodic,
                   bgp.event_history_periodic)
    end
    bgp.event_history_periodic = bgp.default_event_history_periodic
    assert_equal(bgp.default_event_history_periodic,
                 bgp.event_history_periodic)
  end

  def test_fast_external_fallover
    bgp = setup_default
    bgp.fast_external_fallover = true
    assert(bgp.fast_external_fallover,
           'bgp fast-external-fallover should be enabled')
    bgp.fast_external_fallover = false
    refute(bgp.fast_external_fallover,
           'bgp fast-external-fallover should be disabled')
    bgp.destroy
  end

  def test_default_fast_external_fallover
    bgp = setup_default
    assert(bgp.fast_external_fallover,
           'bgp fast-external-fallover default value should be true')
    bgp.destroy
  end

  def test_flush_routes
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.flush_routes)
      assert_raises(UnsupportedError) { bgp.flush_routes = true }
    else
      bgp.flush_routes = true
      assert(bgp.flush_routes,
             'bgp flush-routes should be enabled')
      bgp.flush_routes = false
      refute(bgp.flush_routes,
             'bgp flush-routes should be disabled')
    end
    bgp.destroy
  end

  def test_default_flush_routes
    bgp = setup_default
    refute(bgp.flush_routes,
           'bgp flush-routes value default value should be false')
    bgp.destroy
  end

  def test_graceful_restart_default
    graceful_restart(setup_default)
  end

  def test_graceful_restart_vrf
    graceful_restart(setup_vrf)
  end

  def graceful_restart(bgp)
    if platform == :ios_xr && @vrf != 'default'
      # XR does not support this under a VRF, so test the getter and setter
      assert_nil(bgp.graceful_restart,
                 'graceful_restart should return nil on XR with ' \
                 'non-default vrf')
      assert_raises(Cisco::UnsupportedError) do
        bgp.graceful_restart = true
      end

      assert_nil(bgp.graceful_restart_timers_restart,
                 'graceful_restart_timers_restart should return nil on XR ' \
                 'with non-default vrf')
      assert_raises(Cisco::UnsupportedError) do
        bgp.graceful_restart_timers_restart = 55
      end

      assert_nil(bgp.graceful_restart_timers_stalepath_time,
                 'graceful_restart_timers_stalepath_time should return nil ' \
                 'on XR with non-default vrf')
      assert_raises(Cisco::UnsupportedError) do
        bgp.graceful_restart_timers_stalepath_time = 77
      end
      bgp.destroy
      return
    end
    bgp.graceful_restart = true
    assert(bgp.graceful_restart,
           'bgp graceful restart should be enabled')
    bgp.graceful_restart_timers_restart = 55
    assert_equal(55, bgp.graceful_restart_timers_restart,
                 'bgp graceful restart timers restart' \
                 "should be set to '55'")
    bgp.graceful_restart_timers_stalepath_time = 77
    assert_equal(77, bgp.graceful_restart_timers_stalepath_time,
                 'bgp graceful restart timers stalepath time' \
                 "should be set to '77'")
    if platform == :nexus
      bgp.graceful_restart_helper = true
      assert(bgp.graceful_restart_helper,
             'bgp graceful restart helper should be enabled')
    else
      assert_raises(Cisco::UnsupportedError) do
        bgp.graceful_restart_helper = true
      end
    end
    bgp.graceful_restart = false
    refute(bgp.graceful_restart,
           'bgp graceful_restart should be disabled')
    bgp.graceful_restart_timers_restart = 120
    assert_equal(120, bgp.graceful_restart_timers_restart,
                 'bgp graceful restart timers restart' \
                 "should be set to default value of '120'")
    bgp.graceful_restart_timers_stalepath_time = 300
    assert_equal(300, bgp.graceful_restart_timers_stalepath_time,
                 'bgp graceful restart timers stalepath time' \
                 "should be set to default value of '300'")
    if platform == :nexus
      bgp.graceful_restart_helper = false
      refute(bgp.graceful_restart_helper,
             'bgp graceful restart helper should be disabled')
    else
      assert_raises(Cisco::UnsupportedError) do
        bgp.graceful_restart_helper = false
      end
    end
    bgp.destroy
  end

  def test_default_graceful_restart
    bgp = setup_default
    assert(bgp.default_graceful_restart,
           'bgp graceful restart default value should be enabled = true')
    assert_equal(120, bgp.default_graceful_restart_timers_restart,
                 "bgp graceful restart default timer value should be '120'")
    assert_equal(300, bgp.default_graceful_restart_timers_stalepath_time,
                 "bgp graceful restart default timer value should be '300'")
    if platform == :nexus
      refute(bgp.default_graceful_restart_helper,
             'graceful restart helper default value ' \
             'should be enabled = false')
    else
      assert_nil(bgp.default_graceful_restart_helper,
                 'bgp default_graceful_restart_helper should ' \
                 '*NOT* be supported')
    end
    bgp.destroy
  end

  def test_confederation_id_default
    confederation_id(setup_default)
  end

  def test_confederation_id_vrf
    confederation_id(setup_vrf)
  end

  def confederation_id(bgp)
    if platform == :ios_xr && @vrf != 'default'
      # XR does not support this under a VRF, so test the getter and setter
      assert_nil(bgp.confederation_id,
                 'confederation_id should return nil on XR with ' \
                 'non-default vrf')
      assert_raises(Cisco::UnsupportedError) do
        bgp.confederation_id = 77
      end
      bgp.destroy
      return
    end
    bgp.confederation_id = 77
    assert_equal('77', bgp.confederation_id,
                 "bgp confederation_id should be set to '77'")
    bgp.confederation_id = ''
    assert_empty(bgp.confederation_id, '' \
                 'bgp confederation_id should *NOT* be configured')
    bgp.destroy
  end

  def test_confed_id_uu76828
    bgp = setup_default
    bgp.confederation_id = 55.77
    assert_equal('55.77', bgp.confederation_id,
                 "bgp confederation_id should be set to '55.77'")
    bgp.destroy
  end

  def test_confederation_id_not_configured
    bgp = setup_default
    assert_empty(bgp.confederation_id,
                 'bgp confederation_id should *NOT* be configured')
    bgp.destroy
  end

  def test_default_confederation_id
    bgp = setup_default
    assert_empty(bgp.default_confederation_id,
                 'bgp confederation_id default value should be empty')
    bgp.destroy
  end

  def test_confederation_peers_default
    confed_peers_test(setup_default)
  end

  def test_confederation_peers_vrf
    confed_peers_test(setup_vrf)
  end

  def confed_peers_test(bgp)
    # Confederation peer configuration requires that a
    # confederation id be configured first so the expectation
    # in the next test is an empty peer list
    if platform == :ios_xr && @vrf != 'default'
      # XR does not support this under a VRF, so test the getter and setter
      assert_nil(bgp.confederation_peers,
                 'confederation_peers should return nil on XR ' \
                 'with non-default vrf')
      assert_raises(Cisco::UnsupportedError) do
        bgp.confederation_peers = ['15', '55.77', '16', '18', '555', '299']
      end
      bgp.destroy
      return
    end
    bgp.confederation_id = 55

    assert_empty(bgp.confederation_peers,
                 'bgp confederation_peers list should be empty')
    bgp.confederation_peers = [15]
    assert_equal(['15'], bgp.confederation_peers,
                 "bgp confederation_peers list should be ['15']")
    bgp.confederation_peers = [16]
    assert_equal(['16'], bgp.confederation_peers,
                 "bgp confederation_peers list should be ['16']")
    bgp.confederation_peers = [55.77]
    assert_equal(['55.77'], bgp.confederation_peers,
                 'bgp confederation_peers list should be ' \
                 "['55.77']")
    bgp.confederation_peers = ['15', '55.77', '16', '18', '555', '299']
    assert_equal(['15', '16', '18', '299', '55.77', '555'],
                 bgp.confederation_peers,
                 'bgp confederation_peers list should be ' \
                 "'['15', '16', '18', '299', '55.77', '555']'")
    bgp.confederation_peers = []
    assert_empty(bgp.confederation_peers,
                 'bgp confederation_peers list should be empty')
    bgp.destroy
  end

  def test_confederation_peers_not_configured
    bgp = setup_default
    assert_empty(bgp.confederation_peers,
                 'bgp confederation_peers list should *NOT* be configured')
    bgp.destroy
  end

  def test_default_confederation_peers
    bgp = setup_default
    assert_empty(bgp.default_confederation_peers,
                 'bgp confederation_peers default value should be empty')
    bgp.destroy
  end

  def test_isolate
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.isolate)
      assert_nil(bgp.default_isolate)
      assert_raises(UnsupportedError) { bgp.isolate = true }
    else
      bgp.isolate = true
      assert(bgp.isolate,
             'bgp isolate should be enabled')
      bgp.isolate = false
      refute(bgp.isolate,
             'bgp isolate should be disabled')
    end
    bgp.destroy
  end

  def test_default_isolate
    bgp = setup_default
    refute(bgp.isolate,
           'bgp isolate default value should be false')
    bgp.destroy
  end

  def test_log_neighbor_changes_default
    log_neighbor_changes(setup_default)
  end

  def test_log_neighbor_changes_vrf
    log_neighbor_changes(setup_vrf)
  end

  def log_neighbor_changes(bgp)
    if platform == :ios_xr
      vrf_str = @vrf == 'default' ? '' : "vrf #{@vrf}"
      @default_show_command =
        "show running-config router bgp #{@asnum} #{vrf_str}"
      @default_output_pattern = /bgp log neighbor changes disable/
    else
      @default_show_command = 'show run bgp all'
      @default_output_pattern = /log-neighbor-changes/
    end
    bgp.log_neighbor_changes = false
    refute(bgp.log_neighbor_changes)

    msg_disable = 'log neighbor changes should be disabled'
    msg_enable  = 'log neighbor changes should be enabled'

    if platform == :ios_xr
      # XR the disable keyword added
      assert_show_match(msg: msg_disable)
    else
      # Nexus the command is removed
      refute_show_match(msg: msg_disable)
    end
    bgp.log_neighbor_changes = true
    assert(bgp.log_neighbor_changes)
    if platform == :ios_xr
      # XR removes the whole command including disable keyword
      refute_show_match(msg: msg_enable)
    else
      # Nexus adds the log-neighbor-changes command
      assert_show_match(msg: msg_enable)
    end
    bgp.destroy
  end

  def test_default_log_neighbor_changes
    bgp = setup_default
    if bgp.default_log_neighbor_changes
      # XR logging is on by default
      assert(bgp.log_neighbor_changes,
             'bgp log_neighbor_changes should be enabled')
    else
      refute(bgp.log_neighbor_changes,
             'bgp log_neighbor_changes should be disabled')
    end
    bgp.destroy
  end

  def test_maxas_limit_default
    maxas_limit(setup_default)
  end

  def test_maxas_limit_vrf
    maxas_limit(setup_vrf)
  end

  def maxas_limit(bgp)
    if platform == :ios_xr
      assert_raises(Cisco::UnsupportedError) do
        bgp.maxas_limit = 50
      end
    else
      bgp.maxas_limit = 50
      assert_equal(50, bgp.maxas_limit,
                   "bgp maxas-limit should be set to '50'")
      bgp.maxas_limit = bgp.default_maxas_limit
      assert_equal(bgp.default_maxas_limit, bgp.maxas_limit,
                   'bgp maxas-limit should be set to default value')
    end
    bgp.destroy
  end

  def test_default_maxas_limit
    bgp = setup_default
    assert_equal(bgp.default_maxas_limit, bgp.maxas_limit,
                 'bgp maxas-limit should be default value')
    bgp.destroy
  end

  def test_neighbor_down_fib_accelerate
    if platform == :ios_xr || node.product_id[/N(5|6)/]
      b = RouterBgp.new(1)
      assert_nil(b.neighbor_down_fib_accelerate)
      assert_nil(b.default_neighbor_down_fib_accelerate)
      assert_raises(Cisco::UnsupportedError) do
        b.neighbor_down_fib_accelerate = true
      end
      return
    end
    skip_incompat_version?('bgp', 'neighbor_down_fib_accelerate')
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      default = bgp.default_neighbor_down_fib_accelerate
      assert_equal(default, bgp.neighbor_down_fib_accelerate,
                   'bgp neighbor_fib_down_accelerate not set to default value')

      bgp.neighbor_down_fib_accelerate = true
      assert(bgp.neighbor_down_fib_accelerate,
             "vrf #{@vrf}: bgp neighbor_down_fib_accelerate "\
             'should be enabled')
      bgp.neighbor_down_fib_accelerate = false
      refute(bgp.neighbor_down_fib_accelerate,
             "vrf #{@vrf}: bgp neighbor_down_fib_accelerate "\
             'should be disabled')

      bgp.neighbor_down_fib_accelerate = default
      assert_equal(default, bgp.neighbor_down_fib_accelerate,
                   'bgp neighbor_fib_down_accelerate not set to default value')
      bgp.destroy
    end
  end

  def test_reconnect_interval
    if platform == :ios_xr || node.product_id[/N(5|6)/]
      b = RouterBgp.new(1)
      assert_nil(b.reconnect_interval)
      assert_nil(b.default_reconnect_interval)
      assert_raises(Cisco::UnsupportedError) do
        b.reconnect_interval = 34
      end
      return
    end
    skip_incompat_version?('bgp', 'reconnect_interval')
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          bgp.reconnect_interval = 34
        end
      else
        bgp.reconnect_interval = 34
        assert_equal(34, bgp.reconnect_interval,
                     "vrf #{@vrf}: bgp reconnect_interval should be set to 34")
        bgp.reconnect_interval = 60
        assert_equal(60, bgp.reconnect_interval,
                     "vrf #{@vrf}: bgp reconnect_interval should be set to 60")
      end
      bgp.destroy
    end
  end

  def test_reconnect_interval_default
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.reconnect_interval,
                 'reconnect_interval should return nil on XR')
    else
      skip_incompat_version?('bgp', 'reconnect_interval')
      assert_equal(bgp.default_reconnect_interval, bgp.reconnect_interval,
                   "reconnect_interval should be set to default value of '60'")
      bgp.destroy
    end
  end

  def test_route_distinguisher
    skip_nexus_i2_image?
    remove_all_vrfs
    vdc_limit_f3_no_intf_needed(:set)

    bgp = setup_vrf
    assert_empty(bgp.route_distinguisher,
                 'bgp route_distinguisher should *NOT* be configured')

    bgp.route_distinguisher = 'auto'
    assert_equal('auto', bgp.route_distinguisher)

    bgp.route_distinguisher = '1:1'
    assert_equal('1:1', bgp.route_distinguisher)

    bgp.route_distinguisher = '2:3'
    assert_equal('2:3', bgp.route_distinguisher)

    bgp.route_distinguisher = bgp.default_route_distinguisher
    assert_empty(bgp.route_distinguisher,
                 'bgp route_distinguisher should *NOT* be configured')
    bgp.destroy
    remove_all_vrfs
    vdc_limit_f3_no_intf_needed(:clear)
    config_no_warn('no nv overlay evpn ; no feature nv overlay')
  end

  def test_router_id
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      bgp.router_id = '7.8.9.11'
      assert_equal('7.8.9.11', bgp.router_id,
                   "vrf #{@vrf}: bgp router_id invalid")
      bgp.router_id = ''
      assert_empty(bgp.router_id,
                   "vrf #{@vrf}: bgp router_id should *NOT* be configured")
      bgp.destroy
    end
  end

  def test_router_id_not_configured
    bgp = setup_default
    assert_empty(bgp.router_id,
                 'bgp router_id should *NOT* be configured')
    bgp.destroy
  end

  def test_default_router_id
    bgp = setup_default
    assert_empty(bgp.default_router_id,
                 'bgp router_id default value should be empty')
    bgp.destroy
  end

  def test_shutdown
    bgp = setup_default
    if platform == :ios_xr
      assert_raises(Cisco::UnsupportedError) do
        bgp.shutdown = true
      end
    else
      bgp.shutdown = true
      assert(bgp.shutdown, 'bgp should be shutdown')
      bgp.shutdown = false
      refute(bgp.shutdown, "bgp should in 'no shutdown' state")
    end
    bgp.destroy
  end

  def test_shutdown_not_configured
    bgp = setup_default
    refute(bgp.shutdown,
           "bgp should be in 'no shutdown' state")
    bgp.destroy
  end

  def test_default_shutdown
    bgp = setup_default
    refute(bgp.default_shutdown,
           'bgp shutdown default value should be false')
    bgp.destroy
  end

  def test_suppress_fib_pending
    skip_legacy_defect?('7.0.3.I4',
                        'CSCvd41536: Unable to remove  suppress-fib-pending')
    bgp = setup_default
    if validate_property_excluded?('bgp', 'suppress_fib_pending')
      assert_raises(Cisco::UnsupportedError) do
        bgp.suppress_fib_pending = true
      end
    else
      bgp.suppress_fib_pending = true
      assert(bgp.suppress_fib_pending,
             'bgp suppress_fib_pending should be enabled')
      bgp.suppress_fib_pending = false
      refute(bgp.suppress_fib_pending,
             'bgp suppress_fib_pending should be disabled')
      bgp.suppress_fib_pending = bgp.default_suppress_fib_pending
      assert_equal(bgp.default_suppress_fib_pending, bgp.suppress_fib_pending)
    end
    bgp.destroy
  end

  def test_timer_bestpath_limit
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          bgp.timer_bestpath_limit_set(34)
        end
      else
        bgp.timer_bestpath_limit_set(34)
        assert_equal(34, bgp.timer_bestpath_limit, "vrf #{@vrf}: " \
                     "bgp timer_bestpath_limit should be set to '34'")
        bgp.timer_bestpath_limit_set(300)
        assert_equal(300, bgp.timer_bestpath_limit, "vrf #{@vrf}: " \
                     "bgp timer_bestpath_limit should be set to '300'")
      end
      bgp.destroy
    end
  end

  def test_timer_bestpath_limit_default
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.timer_bestpath_limit,
                 'timer_bestpath_limit should be nil for XR')
    else
      assert_equal(300, bgp.timer_bestpath_limit,
                   "timer_bestpath_limit should be default value of '300'")
    end
    bgp.destroy
  end

  def test_timer_bestpath_limit_always_default
    timer_bestpath_limit_always(setup_default)
  end

  def test_timer_bestpath_limit_always_vrf
    timer_bestpath_limit_always(setup_vrf)
  end

  def timer_bestpath_limit_always(bgp)
    if platform == :ios_xr
      assert_raises(Cisco::UnsupportedError) do
        bgp.timer_bestpath_limit_set(34, true)
      end
    else
      bgp.timer_bestpath_limit_set(34, true)
      assert(bgp.timer_bestpath_limit_always,
             "vrf #{@vrf}: bgp timer_bestpath_limit_always should be enabled")
      bgp.timer_bestpath_limit_set(34, false)
      refute(bgp.timer_bestpath_limit_always,
             "vrf #{@vrf}: bgp timer_bestpath_limit_always should be disabled")
    end
    bgp.destroy
  end

  def test_timer_bestpath_limit_always_not_configured
    bgp = setup_default
    refute(bgp.timer_bestpath_limit_always,
           'bgp timer_bestpath_limit_always should be disabled')
    bgp.destroy
  end

  def test_default_timer_bestpath_limit_always
    bgp = setup_default
    refute(bgp.default_timer_bestpath_limit_always,
           'bgp timer_bestpath_limit_always default value should be false')
    bgp.destroy
  end

  def test_timer_bgp_keepalive_hold
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      bgp.timer_bgp_keepalive_hold_set(25, 45)
      assert_equal(%w(25 45), bgp.timer_bgp_keepalive_hold, "vrf #{@vrf}: " \
                   "keepalive and hold values should be '25 and 45'")
      bgp.timer_bgp_keepalive_hold_set(60, 180)
      assert_equal(%w(60 180), bgp.timer_bgp_keepalive_hold, "vrf #{@vrf}: " \
                   "keepalive and hold values should be '60 and 180'")
      assert_equal(60, bgp.timer_bgp_keepalive, "vrf #{@vrf}: " \
                   "keepalive value should be '60'")
      assert_equal(180, bgp.timer_bgp_holdtime, "vrf #{@vrf}: " \
                   "keepalive value should be '180'")
      bgp.timer_bgp_keepalive_hold_set(500, 3600)
      assert_equal(%w(500 3600), bgp.timer_bgp_keepalive_hold, "vrf #{@vrf}: " \
                   "keepalive and hold values should be '500 and 3600'")
      assert_equal(500, bgp.timer_bgp_keepalive, "vrf #{@vrf}: " \
                   "keepalive value should be '500'")
      assert_equal(3600, bgp.timer_bgp_holdtime, "vrf #{@vrf}: " \
                   "keepalive value should be '3600'")
      bgp.destroy
    end
  end

  def test_default_timer_keepalive_hold_default
    bgp = setup_default
    assert_equal(%w(60 180), bgp.default_timer_bgp_keepalive_hold,
                 'bgp timer_bestpath_timer_keepalive_hold_default values ' \
                 "should be '60' and '180'")
    assert_equal(%w(60 180), bgp.timer_bgp_keepalive_hold,
                 'bgp timer_bestpath_timer_keepalive_hold_default should be' \
                 "set to default values of '60' and '180'")
    bgp.destroy
  end
end
