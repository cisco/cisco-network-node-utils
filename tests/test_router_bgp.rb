#!/usr/bin/env ruby
# RouterBgp Unit Tests
#
# Mike Wiebe, June, 2015
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

# TestRouterBgp - Minitest for RouterBgp class
class TestRouterBgp < CiscoTestCase
  def setup
    # Disable feature bgp before each test to ensure we
    # are starting with a clean slate for each test.
    super
    if platform == :ios_xr
      config('no router bgp')
    else
      config('no feature bgp')
    end
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

  def test_create_asnum_invalid
    ['', 55.5, 'Fifty_Five'].each do |test|
      assert_raises(ArgumentError, "#{test} not a valid asn") do
        RouterBgp.new(test)
      end
    end
  end

  def test_create_vrf_invalid
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

  def test_create_valid_asn
    [1, 4_294_967_295, '55', '1.0', '1.65535',
     '65535.0', '65535.65535'].each do |test|
      bgp = RouterBgp.new(test)
      test = RouterBgp.dot_to_big(test.to_s) if test.is_a? String
      line = get_routerbgp_match_line(test)
      refute_nil(line, "Error: 'router bgp #{test}' not configured")
      bgp.destroy

      vrf = 'Duke'
      bgp = create_bgp_vrf(test, vrf)
      test = RouterBgp.dot_to_big(test.to_s) if test.is_a? String
      line = get_routerbgp_match_line(test, vrf)
      refute_nil(line,
                 "Error: 'router bgp #{test}' vrf '#{vrf}' not configured")
      bgp.destroy
    end
  end

  def test_destroy
    bgp = setup_default
    line = get_routerbgp_match_line(@asnum)
    refute_nil(line, "Error: 'router bgp #{@asnum}' not configured")
    bgp.destroy

    if platform == :ios_xr
      s = config('show run router bgp')
      line = /"router bgp"/.match(s)
      assert_nil(line, "Error: 'router bgp' still configured")
    else
      s = config('show run all | no-more')
      line = /"feature bgp"/.match(s)
      assert_nil(line, "Error: 'feature bgp' still configured")
    end
  end

  def test_create_invalid_multiple
    asnum = 55
    bgp1 = RouterBgp.new(asnum)
    line = get_routerbgp_match_line(asnum)
    refute_nil(line, "Error: 'router bgp #{asnum}' not configured")

    # Only one bgp instance supported so try to create another.
    assert_raises(RuntimeError) do
      bgp2 = RouterBgp.new(88)
      bgp2.destroy unless bgp2.nil?
    end
    bgp1.destroy
  end

  def test_get_asnum
    bgp = setup_default
    line = get_routerbgp_match_line(@asnum)
    asnum = line.to_s.split(' ').last.to_i
    assert_equal(asnum, bgp.asnum,
                 'Error: router asnum not correct')
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

  def test_get_cluster_id_not_configured
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

  def test_set_get_confed_id_uu76828
    bgp = setup_default
    bgp.confederation_id = 55.77
    assert_equal('55.77', bgp.confederation_id,
                 "bgp confederation_id should be set to '55.77'")
    bgp.destroy
  end

  def test_get_confederation_id_not_configured
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

  def test_get_confederation_peers_not_configured
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
    bgp.maxas_limit = 50
    assert_equal(50, bgp.maxas_limit,
                 "bgp maxas-limit should be set to '50'")
    bgp.maxas_limit = bgp.default_maxas_limit
    assert_equal(bgp.default_maxas_limit, bgp.maxas_limit,
                 'bgp maxas-limit should be set to default value')
    bgp.destroy
  end

  def test_default_maxas_limit
    bgp = setup_default
    assert_equal(bgp.default_maxas_limit, bgp.maxas_limit,
                 'bgp maxas-limit should be default value')
    bgp.destroy
  end

  def test_set_get_neighbor_fib_down_accelerate
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      bgp.neighbor_fib_down_accelerate = true
      assert(bgp.neighbor_fib_down_accelerate,
             "vrf #{@vrf}: bgp neighbor_fib_down_accelerate should be enabled")
      bgp.neighbor_fib_down_accelerate = false
      refute(bgp.neighbor_fib_down_accelerate,
             "vrf #{@vrf}: bgp neighbor_fib_down_accelerate should be disabled")
      bgp.destroy
    end
  end

  def test_get_neighbor_fib_down_accelerate_not_configured
    bgp = setup_default
    refute(bgp.neighbor_fib_down_accelerate,
           'bgp neighbor_fib_down_accelerate should be disabled')
    bgp.destroy
  end

  def test_default_neighbor_fib_down_accelerate
    bgp = setup_default
    refute(bgp.default_neighbor_fib_down_accelerate,
           'bgp neighbor_fib_down_accelerate default value should be false')
    bgp.destroy
  end

  def test_set_get_reconnect_interval
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      bgp.reconnect_interval = 34
      assert_equal(34, bgp.reconnect_interval,
                   "vrf #{@vrf}: bgp reconnect_interval should be set to '34'")
      bgp.reconnect_interval = 60
      assert_equal(60, bgp.reconnect_interval,
                   "vrf #{@vrf}: bgp reconnect_interval should be set to '60'")
      bgp.destroy
    end
  end

  def test_get_reconnect_interval_default
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.reconnect_interval,
                 'reconnect_interval should return nil on XR')
    else
      assert_equal(60, bgp.reconnect_interval,
                   "reconnect_interval should be set to default value of '60'")
      bgp.destroy
    end
  end

  def test_route_distinguisher
    bgp = setup_vrf
    bgp.route_distinguisher = 'auto'
    assert_equal('auto', bgp.route_distinguisher,
                 "bgp route_distinguisher should be set to 'auto'")
    bgp.route_distinguisher = '1:1'
    assert_equal('1:1', bgp.route_distinguisher,
                 "bgp route_distinguisher should be set to '1:1'")
    bgp.route_distinguisher = bgp.default_route_distinguisher
    assert_empty(bgp.route_distinguisher,
                 'bgp route_distinguisher should *NOT* be configured')
    bgp.destroy
  end

  def test_default_route_distinguisher
    bgp = setup_vrf
    assert_empty(bgp.default_route_distinguisher,
                 'bgp route_distinguisher default value should be empty')
    bgp.destroy
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

  def test_get_router_id_not_configured
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

  def test_set_get_shutdown
    bgp = setup_default
    bgp.shutdown = true
    assert(bgp.shutdown, 'bgp should be shutdown')
    bgp.shutdown = false
    refute(bgp.shutdown, "bgp should in 'no shutdown' state")
    bgp.destroy
  end

  def test_get_shutdown_not_configured
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

  def test_set_get_suppress_fib_pending
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      bgp.suppress_fib_pending = true
      assert(bgp.suppress_fib_pending,
             "vrf #{@vrf}: bgp suppress_fib_pending should be enabled")
      bgp.suppress_fib_pending = false
      refute(bgp.suppress_fib_pending,
             "vrf #{@vrf}: bgp suppress_fib_pending should be disabled")
      bgp.destroy
    end
  end

  def test_get_suppress_fib_pending_not_configured
    bgp = setup_default
    refute(bgp.suppress_fib_pending,
           'bgp suppress_fib_pending should be disabled')
    bgp.destroy
  end

  def test_default_suppress_fib_pending
    bgp = setup_default
    refute(bgp.default_suppress_fib_pending,
           'bgp suppress_fib_pending default value should be false')
    bgp.destroy
  end

  def test_set_get_timer_bestpath_limit
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        bgp = setup_default
      else
        bgp = setup_vrf
      end
      bgp.timer_bestpath_limit_set(34)
      assert_equal(34, bgp.timer_bestpath_limit, "vrf #{@vrf}: " \
                   "bgp timer_bestpath_limit should be set to '34'")
      bgp.timer_bestpath_limit_set(300)
      assert_equal(300, bgp.timer_bestpath_limit, "vrf #{@vrf}: " \
                   "bgp timer_bestpath_limit should be set to '300'")
      bgp.destroy
    end
  end

  def test_get_timer_bestpath_limit_default
    bgp = setup_default
    if platform == :ios_xr
      assert_nil(bgp.timer_bestpath_limit,
                 'timer_bestpath_limit should be nil for XR')
    else
      assert_equal(300, bgp.timer_bestpath_limit,
                   "timer_bestpath_limit should be default value of '300'")
      bgp.destroy
    end
  end

  def test_timer_bestpath_limit_always_default
    timer_bestpath_limit_always(setup_default)
  end

  def test_timer_bestpath_limit_always_vrf
    timer_bestpath_limit_always(setup_vrf)
  end

  def timer_bestpath_limit_always(bgp)
    bgp.timer_bestpath_limit_set(34, true)
    assert(bgp.timer_bestpath_limit_always,
           "vrf #{@vrf}: bgp timer_bestpath_limit_always should be enabled")
    bgp.timer_bestpath_limit_set(34, false)
    refute(bgp.timer_bestpath_limit_always,
           "vrf #{@vrf}: bgp timer_bestpath_limit_always should be disabled")
    bgp.destroy
  end

  def test_get_timer_bestpath_limit_always_not_configured
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

  def test_default_timer_bgp_keepalive_hold_default
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
