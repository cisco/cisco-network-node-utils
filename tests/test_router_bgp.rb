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

XR_SUPPORTED_BROKEN  = 'Supported in IOS XR - needs further work'

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

  def test_routerbgp_collection_empty
    if platform == :ios_xr
      config('no router bgp')
    else
      config('no feature bgp')
    end
    routers = RouterBgp.routers
    assert_empty(routers, 'RouterBgp collection is not empty')
  end

  def test_routerbgp_collection_not_empty
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

  def test_routerbgp_create_asnum_invalid
    ['', 55.5, 'Fifty_Five'].each do |test|
      assert_raises(ArgumentError, "#{test} not a valid asn") do
        RouterBgp.new(test)
      end
    end
  end

  def test_routerbgp_create_vrf_invalid
    ['', 55].each do |test|
      assert_raises(ArgumentError, "#{test} not a valid vrf name") do
        RouterBgp.new(88, test)
      end
    end
  end

  def test_routerbgp_create_vrfname_zero_length
    asnum = 55
    assert_raises(ArgumentError) do
      RouterBgp.new(asnum, '')
    end
  end

  def test_routerbgp_create_valid
    asnum = 55
    bgp = RouterBgp.new(asnum)
    line = get_routerbgp_match_line(asnum)
    refute_nil(line, "Error: 'router bgp #{asnum}' not configured")
    bgp.destroy

    vrf = 'wolfpack'
    bgp = create_bgp_vrf(asnum, vrf)
    line = get_routerbgp_match_line(asnum, vrf)
    refute_nil(line, "Error: 'router bgp #{asnum}' vrf '#{vrf}' not configured")
    bgp.destroy
  end

  def test_routerbgp_create_valid_asn
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

  def test_routerbgp_create_valid_no_feature
    asnum = 55
    bgp = RouterBgp.new(asnum)
    line = get_routerbgp_match_line(asnum)
    refute_nil(line, "Error: 'router bgp #{asnum}' not configured")
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

  def test_routerbgp_create_invalid_multiple
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

  def test_routerbgp_get_asnum
    asnum = 55
    bgp = RouterBgp.new(asnum)
    line = get_routerbgp_match_line(asnum)
    asnum = line.to_s.split(' ').last.to_i
    assert_equal(asnum, bgp.asnum,
                 'Error: router asnum not correct')
    bgp.destroy
  end

  def test_routerbgp_destroy
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.destroy
    line = get_routerbgp_match_line(asnum)
    assert_nil(line, "Error: 'router bgp #{asnum}' not destroyed")
  end

  def test_routerbgp_set_get_bestpath
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      bgp.bestpath_always_compare_med = true
      assert(bgp.bestpath_always_compare_med, "vrf #{vrf}: "\
             'bgp bestpath_always_compare_med should be enabled')
      bgp.bestpath_aspath_multipath_relax = true
      assert(bgp.bestpath_aspath_multipath_relax, "vrf #{vrf}: "\
             'bgp bestpath_aspath_multipath_relax should be enabled')
      bgp.bestpath_compare_routerid = true
      assert(bgp.bestpath_compare_routerid, "vrf #{vrf}: "\
             'bgp bestpath_compare_routerid should be enabled')
      bgp.bestpath_cost_community_ignore = true
      assert(bgp.bestpath_cost_community_ignore, "vrf #{vrf}: "\
             'bgp bestpath_cost_community_ignore should be enabled')
      bgp.bestpath_med_confed = true
      if platform == :nexus ||
         (platform == :ios_xr && vrf == 'default')
        # TODO: This property only works on IOS XR at the global level.
        assert(bgp.bestpath_med_confed, "vrf #{vrf}: "\
               'bgp bestpath_med_confed should be enabled')
      end
      bgp.bestpath_med_missing_as_worst = true
      assert(bgp.bestpath_med_missing_as_worst, "vrf #{vrf}: "\
             'bgp bestpath_med_missing_as_worst should be enabled')
      if platform == :nexus
        # TODO: only applies to :nexus
        bgp.bestpath_med_non_deterministic = true
        assert(bgp.bestpath_med_non_deterministic, "vrf #{vrf}: "\
               'bgp bestpath_med_non_deterministic should be enabled')
      end
      bgp.bestpath_always_compare_med = false
      refute(bgp.bestpath_always_compare_med, "vrf #{vrf}: "\
             'bgp bestpath_always_compare_med should be disabled')
      bgp.bestpath_aspath_multipath_relax = false
      refute(bgp.bestpath_aspath_multipath_relax, "vrf #{vrf}: "\
             'bgp bestpath_aspath_multipath_relax should be disabled')
      bgp.bestpath_compare_routerid = false
      refute(bgp.bestpath_compare_routerid, "vrf #{vrf}: "\
             'bgp bestpath_compare_routerid should be disabled')
      bgp.bestpath_cost_community_ignore = false
      refute(bgp.bestpath_cost_community_ignore, "vrf #{vrf}: "\
             'bgp bestpath_cost_community_ignore should be disabled')
      bgp.bestpath_med_confed = false
      refute(bgp.bestpath_med_confed, "vrf #{vrf}: "\
             'bgp bestpath_med_confed should be disabled')
      bgp.bestpath_med_missing_as_worst = false
      refute(bgp.bestpath_med_missing_as_worst, "vrf #{vrf}: "\
             'bgp bestpath_med_missing_as_worst should be disabled')
      if platform == :nexus
        # TODO: Only applies to :nexus
        bgp.bestpath_med_non_deterministic = false
        refute(bgp.bestpath_med_non_deterministic, "vrf #{vrf}: "\
             'bgp bestpath_med_non_deterministic should be disabled')
      end
      bgp.destroy
    end
  end

  def test_routerbgp_get_bestpath_not_configured
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      refute(bgp.bestpath_always_compare_med, "vrf #{vrf}: "\
             'bgp bestpath_always_compare_med should *NOT* be enabled')
      refute(bgp.bestpath_aspath_multipath_relax, "vrf #{vrf}: "\
             'bgp bestpath_aspath_multipath_relax should *NOT* be enabled')
      refute(bgp.bestpath_compare_routerid, "vrf #{vrf}: "\
             'bgp bestpath_compare_routerid should be *NOT* enabled')
      refute(bgp.bestpath_cost_community_ignore, "vrf #{vrf}: "\
             'bgp bestpath_cost_community_ignore should *NOT* be enabled')
      refute(bgp.bestpath_med_confed, "vrf #{vrf}: "\
             'bgp bestpath_med_confed should *NOT* be enabled')
      refute(bgp.bestpath_med_missing_as_worst, "vrf #{vrf}: "\
             'bgp bestpath_med_missing_as_worst should *NOT* be enabled')
      if platform == :nexus
        # TODO: Only applies to :nexus
        refute(bgp.bestpath_med_non_deterministic, "vrf #{vrf}: "\
             'bgp bestpath_med_non_deterministic should *NOT* be enabled')
      end
      bgp.destroy
    end
  end

  def test_routerbgp_default_bestpath
    asnum = 55
    bgp = RouterBgp.new(asnum)
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
      # TODO: Only applies to :nexus
      refute(bgp.default_bestpath_med_non_deterministic,
             'default value for bestpath_med_non_deterministic should be false')
    end
    bgp.destroy
  end

  def test_routerbgp_set_get_cluster_id
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        next if platform == :ios_xr
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      bgp.cluster_id = 34
      assert_equal('34', bgp.cluster_id,
                   "vrf #{vrf}: bgp cluster_id should be set to '34'")
      bgp.cluster_id = '1.2.3.4'
      assert_equal('1.2.3.4', bgp.cluster_id,
                   "vrf #{vrf}: bgp cluster_id should be set to '1.2.3.4'")
      bgp.cluster_id = ''
      assert_empty(bgp.cluster_id,
                   "vrf #{vrf}: bgp cluster_id should *NOT* be configured")
      bgp.destroy
    end
  end

  def test_routerbgp_get_cluster_id_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.cluster_id,
                 'bgp cluster_id should *NOT* be configured')
    bgp.destroy
  end

  def test_routerbgp_default_cluster_id
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_cluster_id,
                 'bgp cluster_id default value should be empty')
    bgp.destroy
  end

  def test_routerbgp_set_get_enforce_first_as
    skip(XR_SUPPORTED_BROKEN) if platform == :ios_xr
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.enforce_first_as = true
    assert(bgp.enforce_first_as,
           'bgp enforce-first-as should be enabled')
    bgp.enforce_first_as = false
    refute(bgp.enforce_first_as,
           'bgp enforce-first-as should be disabled')
    bgp.destroy
  end

  def test_routerbgp_default_enforce_first_as
    skip(XR_SUPPORTED_BROKEN) if platform == :ios_xr
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert(bgp.enforce_first_as,
           'bgp enforce-first-as value should be enabled = true')
    bgp.destroy
  end

  def test_routerbgp_set_get_graceful_restart
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        # Non-default VRF does not apply to IOS XR
        next if platform == :ios_xr
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      bgp.graceful_restart = true
      assert(bgp.graceful_restart,
             "vrf #{vrf}: bgp graceful restart should be enabled")
      bgp.graceful_restart_timers_restart = 55
      assert_equal(55, bgp.graceful_restart_timers_restart,
                   "vrf #{vrf}: bgp graceful restart timers restart" \
                   "should be set to '55'")
      bgp.graceful_restart_timers_stalepath_time = 77
      assert_equal(77, bgp.graceful_restart_timers_stalepath_time,
                   "vrf #{vrf}: bgp graceful restart timers stalepath time" \
                   "should be set to '77'")
      if platform == :nexus
        # TODO: Only applies to :nexus
        bgp.graceful_restart_helper = true
        assert(bgp.graceful_restart_helper,
               "vrf #{vrf}: bgp graceful restart helper should be enabled")
      end
      bgp.graceful_restart = false
      refute(bgp.graceful_restart,
             "vrf #{vrf}: bgp graceful_restart should be disabled")
      bgp.graceful_restart_timers_restart = 120
      assert_equal(120, bgp.graceful_restart_timers_restart,
                   "vrf #{vrf}: bgp graceful restart timers restart" \
                   "should be set to default value of '120'")
      bgp.graceful_restart_timers_stalepath_time = 300
      assert_equal(300, bgp.graceful_restart_timers_stalepath_time,
                   "vrf #{vrf}: bgp graceful restart timers stalepath time" \
                   "should be set to default value of '300'")
      if platform == :nexus
        # TODO: Only applies to :nexus
        bgp.graceful_restart_helper = false
        refute(bgp.graceful_restart_helper,
               "vrf #{vrf}: bgp graceful restart helper should be disabled")
      end
      bgp.destroy
    end
  end

  def test_routerbgp_default_graceful_restart
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert(bgp.default_graceful_restart,
           'bgp graceful restart default value should be enabled = true')
    assert_equal(120, bgp.default_graceful_restart_timers_restart,
                 "bgp graceful restart default timer value should be '120'")
    assert_equal(300, bgp.default_graceful_restart_timers_stalepath_time,
                 "bgp graceful restart default timer value should be '300'")
    # rubocop:disable Style/GuardClause
    if platform == :nexus
      refute(bgp.default_graceful_restart_helper,
             'graceful restart helper default value ' \
             'should be enabled = false')
    end
    # rubocop:enable Style/GuardClause
  end

  def test_routerbgp_set_get_confederation_id
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        # Non-default VRF does not apply to IOS XR
        next if platform == :ios_xr
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      bgp.confederation_id = 77
      assert_equal('77', bgp.confederation_id,
                   "vrf #{vrf}: bgp confederation_id should be set to '77'")
      bgp.confederation_id = ''
      assert_empty(bgp.confederation_id, "vrf #{vrf}: " \
                   'bgp confederation_id should *NOT* be configured')
      bgp.destroy
    end
  end

  def test_routerbgp_set_get_confed_id_uu76828
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.confederation_id = 55.77
    assert_equal('55.77', bgp.confederation_id,
                 "bgp confederation_id should be set to '55.77'")
  end

  def test_routerbgp_get_confederation_id_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.confederation_id,
                 'bgp confederation_id should *NOT* be configured')
    bgp.destroy
  end

  def test_routerbgp_default_confederation_id
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_confederation_id,
                 'bgp confederation_id default value should be empty')
    bgp.destroy
  end

  def test_routerbgp_set_get_confederation_peers
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        next if platform == :ios_xr
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      # Confederation peer configuration requires that a
      # confederation id be configured first so the expectation
      # in the next test is an empty peer list
      bgp.confederation_id = 55

      assert_empty(bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be empty")
      bgp.confederation_peers = (15)
      assert_equal("15", bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be '15'")
      bgp.confederation_peers = (16)
      assert_equal('16', bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be '16'")
      bgp.confederation_peers = (55.77)
      assert_equal('55.77', bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be " \
                   "'55.77'")
      bgp.confederation_peers = ('15 16 55.77 18 555 299')
      assert_equal('15 16 18 299 555 55.77',
                   bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be " \
                   "'15 16 18 299 555 55.77'")
      bgp.confederation_peers = ('')
      assert_empty(bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be empty")
      bgp.destroy
    end
  end

  def test_routerbgp_get_confederation_peers_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.confederation_peers,
                 'bgp confederation_peers list should *NOT* be configured')
    bgp.destroy
  end

  def test_routerbgp_default_confederation_peers
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_confederation_peers,
                 'bgp confederation_peers default value should be empty')
    bgp.destroy
  end

  def test_routerbgp_set_get_log_neighbor_changes
    skip(XR_SUPPORTED_BROKEN) if platform == :ios_xr
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = RouterBgp.new(asnum, vrf)
      end
      bgp.log_neighbor_changes = true
      assert(bgp.log_neighbor_changes,
             "vrf #{vrf}: bgp log_neighbor_changes should be enabled")
      bgp.log_neighbor_changes = false
      refute(bgp.log_neighbor_changes,
             "vrf #{vrf}: bgp log_neighbor_changes should be disabled")
      bgp.destroy
    end
  end

  def test_routerbgp_get_log_neighbor_changes_not_configured
    skip(XR_SUPPORTED_BROKEN) if platform == :ios_xr
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.log_neighbor_changes,
           'bgp log_neighbor_changes should be disabled')
    bgp.destroy
  end

  def test_routerbgp_default_log_neighbor_changes
    skip(XR_SUPPORTED_BROKEN) if platform == :ios_xr
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_log_neighbor_changes,
           'bgp log_neighbor_changes default value should be false')
    bgp.destroy
  end

  def test_routerbgp_set_get_maxas_limit
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = RouterBgp.new(asnum, vrf)
      end
      bgp.maxas_limit = 50
      assert_equal(50, bgp.maxas_limit,
                   "vrf #{vrf}: bgp maxas-limit should be set to '50'")
      bgp.maxas_limit = bgp.default_maxas_limit
      assert_equal(bgp.default_maxas_limit, bgp.maxas_limit,
                   "vrf #{vrf}: bgp maxas-limit should be set to default value")
      bgp.destroy
    end
  end

  def test_routerbgp_default_maxas_limit
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(bgp.default_maxas_limit, bgp.maxas_limit,
                 'bgp maxas-limit should be default value')
    bgp.destroy
  end

  def test_routerbgp_set_get_neighbor_fib_down_accelerate
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = RouterBgp.new(asnum, vrf)
      end
      bgp.neighbor_fib_down_accelerate = true
      assert(bgp.neighbor_fib_down_accelerate,
             "vrf #{vrf}: bgp neighbor_fib_down_accelerate should be enabled")
      bgp.neighbor_fib_down_accelerate = false
      refute(bgp.neighbor_fib_down_accelerate,
             "vrf #{vrf}: bgp neighbor_fib_down_accelerate should be disabled")
      bgp.destroy
    end
  end

  def test_routerbgp_get_neighbor_fib_down_accelerate_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.neighbor_fib_down_accelerate,
           'bgp neighbor_fib_down_accelerate should be disabled')
    bgp.destroy
  end

  def test_routerbgp_default_neighbor_fib_down_accelerate
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_neighbor_fib_down_accelerate,
           'bgp neighbor_fib_down_accelerate default value should be false')
    bgp.destroy
  end

  def test_routerbgp_set_get_reconnect_interval
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = RouterBgp.new(asnum, vrf)
      end
      bgp.reconnect_interval = 34
      assert_equal(34, bgp.reconnect_interval,
                   "vrf #{vrf}: bgp reconnect_interval should be set to '34'")
      bgp.reconnect_interval = 60
      assert_equal(60, bgp.reconnect_interval,
                   "vrf #{vrf}: bgp reconnect_interval should be set to '60'")
      bgp.destroy
    end
  end

  def test_routerbgp_get_reconnect_interval_default
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(60, bgp.reconnect_interval,
                 "reconnect_interval should be set to default value of '60'")
    bgp.destroy
  end

  def test_routerbgp_set_get_router_id
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      bgp.router_id = '1.2.3.4'
      assert_equal('1.2.3.4', bgp.router_id,
                   "vrf #{vrf}: bgp router_id should be set to '1.2.3.4'")
      bgp.router_id = ''
      assert_empty(bgp.router_id,
                   "vrf #{vrf}: bgp router_id should *NOT* be configured")
      bgp.destroy
    end
  end

  def test_routerbgp_get_router_id_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.router_id,
                 'bgp router_id should *NOT* be configured')
    bgp.destroy
  end

  def test_routerbgp_default_router_id
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_router_id,
                 'bgp router_id default value should be empty')
    bgp.destroy
  end

  def test_routerbgp_set_get_shutdown
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.shutdown = true
    assert(bgp.shutdown, 'bgp should be shutdown')
    bgp.shutdown = false
    refute(bgp.shutdown, "bgp should in 'no shutdown' state")
    bgp.destroy
  end

  def test_routerbgp_get_shutdown_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.shutdown,
           "bgp should be in 'no shutdown' state")
    bgp.destroy
  end

  def test_routerbgp_default_shutdown
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_shutdown,
           'bgp shutdown default value should be false')
    bgp.destroy
  end

  def test_routerbgp_set_get_suppress_fib_pending
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = RouterBgp.new(asnum, vrf)
      end
      bgp.suppress_fib_pending = true
      assert(bgp.suppress_fib_pending,
             "vrf #{vrf}: bgp suppress_fib_pending should be enabled")
      bgp.suppress_fib_pending = false
      refute(bgp.suppress_fib_pending,
             "vrf #{vrf}: bgp suppress_fib_pending should be disabled")
      bgp.destroy
    end
  end

  def test_routerbgp_get_suppress_fib_pending_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.suppress_fib_pending,
           'bgp suppress_fib_pending should be disabled')
    bgp.destroy
  end

  def test_routerbgp_default_suppress_fib_pending
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_suppress_fib_pending,
           'bgp suppress_fib_pending default value should be false')
    bgp.destroy
  end

  def test_routerbgp_set_get_timer_bestpath_limit
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = RouterBgp.new(asnum, vrf)
      end
      bgp.timer_bestpath_limit_set(34)
      assert_equal(34, bgp.timer_bestpath_limit, "vrf #{vrf}: " \
                   "bgp timer_bestpath_limit should be set to '34'")
      bgp.timer_bestpath_limit_set(300)
      assert_equal(300, bgp.timer_bestpath_limit, "vrf #{vrf}: " \
                   "bgp timer_bestpath_limit should be set to '300'")
      bgp.destroy
    end
  end

  def test_routerbgp_get_timer_bestpath_limit_default
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(300, bgp.timer_bestpath_limit,
                 "timer_bestpath_limit should be default value of '300'")
    bgp.destroy
  end

  def test_routerbgp_set_get_timer_bestpath_limit_always
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = RouterBgp.new(asnum, vrf)
      end
      bgp.timer_bestpath_limit_set(34, true)
      assert(bgp.timer_bestpath_limit_always,
             "vrf #{vrf}: bgp timer_bestpath_limit_always should be enabled")
      bgp.timer_bestpath_limit_set(34, false)
      refute(bgp.timer_bestpath_limit_always,
             "vrf #{vrf}: bgp timer_bestpath_limit_always should be disabled")
      bgp.destroy
    end
  end

  def test_routerbgp_get_timer_bestpath_limit_always_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.timer_bestpath_limit_always,
           'bgp timer_bestpath_limit_always should be disabled')
    bgp.destroy
  end

  def test_routerbgp_default_timer_bestpath_limit_always
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_timer_bestpath_limit_always,
           'bgp timer_bestpath_limit_always default value should be false')
    bgp.destroy
  end

  def test_routerbgp_set_get_timer_bgp_keepalive_hold
    %w(test_default test_vrf).each do |t|
      if t == 'test_default'
        asnum = 55
        vrf = 'default'
        bgp = RouterBgp.new(asnum)
      else
        asnum = 99
        vrf = 'yamllll'
        bgp = create_bgp_vrf(asnum, vrf)
      end
      bgp.timer_bgp_keepalive_hold_set(25, 45)
      assert_equal(%w(25 45), bgp.timer_bgp_keepalive_hold, "vrf #{vrf}: " \
                   "keepalive and hold values should be '25 and 45'")
      bgp.timer_bgp_keepalive_hold_set(60, 180)
      assert_equal(%w(60 180), bgp.timer_bgp_keepalive_hold, "vrf #{vrf}: " \
                   "keepalive and hold values should be '60 and 180'")
      assert_equal(60, bgp.timer_bgp_keepalive, "vrf #{vrf}: " \
                   "keepalive value should be '60'")
      assert_equal(180, bgp.timer_bgp_holdtime, "vrf #{vrf}: " \
                   "keepalive value should be '180'")
      bgp.timer_bgp_keepalive_hold_set(500, 3600)
      assert_equal(%w(500 3600), bgp.timer_bgp_keepalive_hold, "vrf #{vrf}: " \
                   "keepalive and hold values should be '500 and 3600'")
      assert_equal(500, bgp.timer_bgp_keepalive, "vrf #{vrf}: " \
                   "keepalive value should be '500'")
      assert_equal(3600, bgp.timer_bgp_holdtime, "vrf #{vrf}: " \
                   "keepalive value should be '3600'")
      bgp.destroy
    end
  end

  def test_routerbgp_default_timer_keepalive_hold_default
    skip(XR_SUPPORTED_BROKEN) if platform == :ios_xr
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(%w(60 180), bgp.default_timer_bgp_keepalive_hold,
                 'bgp timer_bestpath_timer_keepalive_hold_default values ' \
                 "should be '60' and '180'")
    assert_equal(%w(60 180), bgp.timer_bgp_keepalive_hold,
                 'bgp timer_bestpath_timer_keepalive_hold_default should be' \
                 "set to default values of '60' and '180'")
    bgp.destroy
  end
end
