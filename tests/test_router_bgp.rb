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

# TestRouterBgp - Minitest for RouterBgp class
class TestRouterBgp < CiscoTestCase
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

  def get_routerbgp_match_line(as_number, vrf='default')
    s = @device.cmd("show run | section '^router bgp .*'")
    if vrf == 'default'
      line = /router bgp\s#{as_number}/.match(s)
    else
      line = /vrf #{vrf}/.match(s)
    end
    line
  end

  def test_collection_empty
    config('no feature bgp')
    node.cache_flush
    routers = RouterBgp.routers
    assert_empty(routers, 'RouterBgp collection is not empty')
  end

  def test_collection_not_empty
    config('feature bgp',
           'router bgp 55',
           'vrf blue',
           'vrf red',
           'vrf white')
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
    asnum = 55
    bgp = RouterBgp.new(asnum)
    line = get_routerbgp_match_line(asnum)
    refute_nil(line, "Error: 'router bgp #{asnum}' not configured")
    bgp.destroy

    vrf = 'wolfpack'
    bgp = RouterBgp.new(asnum, vrf)
    line = get_routerbgp_match_line(asnum, vrf)
    refute_nil(line, "Error: 'router bgp #{asnum}' vrf '#{vrf}' not configured")
    bgp.destroy
  end

  def test_valid_asn
    [1, 4_294_967_295, '55', '1.0', '1.65535',
     '65535.0', '65535.65535'].each do |test|
      rtr_bgp = RouterBgp.new(test)
      assert_equal(test.to_s, RouterBgp.routers.keys[0].to_s)
      rtr_bgp.destroy

      vrf = 'Duke'
      bgp_vrf = RouterBgp.new(test, vrf)
      assert_equal(test.to_s, RouterBgp.routers.keys[0].to_s)
      bgp_vrf.destroy
      rtr_bgp.destroy
    end
  end

  def test_create_valid_no_feature
    asnum = 55
    bgp = RouterBgp.new(asnum)
    line = get_routerbgp_match_line(asnum)
    refute_nil(line, "Error: 'router bgp #{asnum}' not configured")
    bgp.destroy

    s = @device.cmd('show run all | no-more')
    line = /"feature bgp"/.match(s)
    assert_nil(line, "Error: 'feature bgp' still configured")
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

  def test_destroy
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.destroy
    line = get_routerbgp_match_line(asnum)
    assert_nil(line, "Error: 'router bgp #{asnum}' not destroyed")
  end

  def test_bestpath
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
      assert(bgp.bestpath_med_confed, "vrf #{vrf}: "\
             'bgp bestpath_med_confed should be enabled')
      bgp.bestpath_med_missing_as_worst = true
      assert(bgp.bestpath_med_missing_as_worst, "vrf #{vrf}: "\
             'bgp bestpath_med_missing_as_worst should be enabled')
      bgp.bestpath_med_non_deterministic = true
      assert(bgp.bestpath_med_non_deterministic, "vrf #{vrf}: "\
             'bgp bestpath_med_non_deterministic should be enabled')

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
      bgp.bestpath_med_non_deterministic = false
      refute(bgp.bestpath_med_non_deterministic, "vrf #{vrf}: "\
             'bgp bestpath_med_non_deterministic should be disabled')
      bgp.destroy
    end
  end

  def test_bestpath_not_configured
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
      refute(bgp.bestpath_med_non_deterministic, "vrf #{vrf}: "\
             'bgp bestpath_med_non_deterministic should *NOT* be enabled')
      bgp.destroy
    end
  end

  def test_default_bestpath
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
    refute(bgp.default_bestpath_med_non_deterministic,
           'default value for bestpath_med_non_deterministic should be false')
    bgp.destroy
  end

  def test_cluster_id
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

  def test_cluster_id_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.cluster_id,
                 'bgp cluster_id should *NOT* be configured')
    bgp.destroy
  end

  def test_default_cluster_id
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_cluster_id,
                 'bgp cluster_id default value should be empty')
    bgp.destroy
  end

  def test_disable_policy_batching
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.disable_policy_batching = true
    assert(bgp.disable_policy_batching,
           'bgp disable-policy-batching should be enabled')
    bgp.disable_policy_batching = false
    refute(bgp.disable_policy_batching,
           'bgp disable-policy-batching should be disabled')
    bgp.destroy
  end

  def test_default_disable_policy_batching
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.disable_policy_batching,
           'bgp disable-policy-batching value should be false')
    bgp.destroy
  end

  def test_disable_policy_batching_ipv4
    bgp = RouterBgp.new(55)
    bgp.disable_policy_batching_ipv4 = 'xx'
    assert_equal('xx', bgp.disable_policy_batching_ipv4,
                 "bgp disable_policy_batching_ipv4 should be set to 'xx'")
    bgp.disable_policy_batching_ipv4 = bgp.default_disable_policy_batching_ipv4
    assert_empty(bgp.disable_policy_batching_ipv4,
                 'bgp disable_policy_batching_ipv4 should be empty')
    bgp.destroy
  end

  def test_default_disable_policy_batching_ipv4
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(bgp.default_disable_policy_batching_ipv4,
                 bgp.disable_policy_batching_ipv4,
                 'disable_policy_batching_ipv4 default value should be empty')
    bgp.destroy
  end

  def test_disable_policy_batching_ipv6
    bgp = RouterBgp.new(55)
    bgp.disable_policy_batching_ipv6 = 'xx'
    assert_equal('xx', bgp.disable_policy_batching_ipv6,
                 "bgp disable_policy_batching_ipv6 should be set to 'xx'")
    bgp.disable_policy_batching_ipv6 = bgp.default_disable_policy_batching_ipv6
    assert_empty(bgp.disable_policy_batching_ipv6,
                 'bgp disable_policy_batching_ipv6 should be empty')
    bgp.destroy
  end

  def test_default_disable_policy_batching_ipv6
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(bgp.default_disable_policy_batching_ipv6,
                 bgp.disable_policy_batching_ipv6,
                 'disable_policy_batching_ipv6 default value should be empty')
    bgp.destroy
  end

  def test_enforce_first_as
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

  def test_default_enforce_first_as
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert(bgp.enforce_first_as,
           'bgp enforce-first-as value should be enabled = true')
    bgp.destroy
  end

  def test_event_history
    bgp = RouterBgp.new(55)

    opts = [:cli, :detail, :events, :periodic]
    opts.each do |opt|
      # Test basic true
      bgp.send("event_history_#{opt}=", 'true')
      set = bgp.send("default_event_history_#{opt}")
      result = bgp.send("event_history_#{opt}")
      assert_equal(set, result,
                   "event_history_#{opt}: Failed to set to default state")

      # Test true with size
      bgp.send("event_history_#{opt}=", 'size_large')
      result = bgp.send("event_history_#{opt}")
      assert_equal('size_large', result,
                   "event_history_#{opt}: Failed to set True with Size large")

      # Test false with size
      bgp.send("event_history_#{opt}=", 'false')
      result = bgp.send("event_history_#{opt}")
      expected = (opt == :detail) ? bgp.default_event_history_detail : 'false'
      assert_equal(expected, result,
                   "event_history_#{opt}: Failed to set state to False")

      # Test true with size, from false
      bgp.send("event_history_#{opt}=", 'size_small')
      result = bgp.send("event_history_#{opt}")
      assert_equal('size_small', result,
                   "event_history_#{opt}: Failed to set True with "\
                   'Size from false state')

      # Test default_state
      set = bgp.send("default_event_history_#{opt}")
      bgp.send("event_history_#{opt}=", set)
      result = bgp.send("event_history_#{opt}")
      assert_equal(set, result,
                   "event_history_#{opt}: Failed to set state to default")
    end
  end

  def test_fast_external_fallover
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.fast_external_fallover = true
    assert(bgp.fast_external_fallover,
           'bgp fast-external-fallover should be enabled')
    bgp.fast_external_fallover = false
    refute(bgp.fast_external_fallover,
           'bgp fast-external-fallover should be disabled')
    bgp.destroy
  end

  def test_default_fast_external_fallover
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert(bgp.fast_external_fallover,
           'bgp fast-external-fallover default value should be true')
    bgp.destroy
  end

  def test_flush_routes
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.flush_routes = true
    assert(bgp.flush_routes,
           'bgp flush-routes should be enabled')
    bgp.flush_routes = false
    refute(bgp.flush_routes,
           'bgp flush-routes should be disabled')
    bgp.destroy
  end

  def test_default_flush_routes
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.flush_routes,
           'bgp flush-routes value default value should be false')
    bgp.destroy
  end

  def test_graceful_restart
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
      bgp.graceful_restart_helper = true
      assert(bgp.graceful_restart_helper,
             "vrf #{vrf}: bgp graceful restart helper should be enabled")

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
      bgp.graceful_restart_helper = false
      refute(bgp.graceful_restart_helper,
             "vrf #{vrf}: bgp graceful restart helper should be disabled")
      bgp.destroy
    end
  end

  def test_default_graceful_restart
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert(bgp.default_graceful_restart,
           'bgp graceful restart default value should be enabled = true')
    assert_equal(120, bgp.default_graceful_restart_timers_restart,
                 "bgp graceful restart default timer value should be '120'")
    assert_equal(300, bgp.default_graceful_restart_timers_stalepath_time,
                 "bgp graceful restart default timer value should be '300'")
    refute(bgp.default_graceful_restart_helper,
           'graceful restart helper default value should be enabled = false')
  end

  def test_confederation_id
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
      bgp.confederation_id = 77
      assert_equal('77', bgp.confederation_id,
                   "vrf #{vrf}: bgp confederation_id should be set to '77'")
      bgp.confederation_id = ''
      assert_empty(bgp.confederation_id, "vrf #{vrf}: " \
                   'bgp confederation_id should *NOT* be configured')
      bgp.destroy
    end
  end

  def test_confed_id_uu76828
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.confederation_id = 55.77
    assert_equal('55.77', bgp.confederation_id,
                 "bgp confederation_id should be set to '55.77'")
  end

  def test_confederation_id_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.confederation_id,
                 'bgp confederation_id should *NOT* be configured')
    bgp.destroy
  end

  def test_default_confederation_id
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_confederation_id,
                 'bgp confederation_id default value should be empty')
    bgp.destroy
  end

  def test_confederation_peers
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
      # Confederation peer configuration requires that a
      # confederation id be configured first so the expectation
      # in the next test is an empty peer list
      bgp.confederation_id = 55
      assert_empty(bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be empty")
      bgp.confederation_peers_set(15)
      assert_equal('15', bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be '15'")
      bgp.confederation_peers_set(16)
      assert_equal('16', bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be '16'")
      bgp.confederation_peers_set(55.77)
      assert_equal('55.77', bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be" \
                   "'55.77'")
      bgp.confederation_peers_set('15 16 55.77 18 555 299')
      assert_equal('15 16 55.77 18 555 299',
                   bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be" \
                   "'15 16 55.77 18 555 299'")
      bgp.confederation_peers_set('')
      assert_empty(bgp.confederation_peers,
                   "vrf #{vrf}: bgp confederation_peers list should be empty")
      bgp.destroy
    end
  end

  def test_confederation_peers_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.confederation_peers,
                 'bgp confederation_peers list should *NOT* be configured')
    bgp.destroy
  end

  def test_default_confederation_peers
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_confederation_peers,
                 'bgp confederation_peers default value should be empty')
    bgp.destroy
  end

  def test_isolate
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.isolate = true
    assert(bgp.isolate,
           'bgp isolate should be enabled')
    bgp.isolate = false
    refute(bgp.isolate,
           'bgp isolate should be disabled')
    bgp.destroy
  end

  def test_default_isolate
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.isolate,
           'bgp isolate default value should be false')
    bgp.destroy
  end

  def test_log_neighbor_changes
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

  def test_log_neighbor_changes_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.log_neighbor_changes,
           'bgp log_neighbor_changes should be disabled')
    bgp.destroy
  end

  def test_default_log_neighbor_changes
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_log_neighbor_changes,
           'bgp log_neighbor_changes default value should be false')
    bgp.destroy
  end

  def maxas_limit(vrf)
    bgp = RouterBgp.new(55, vrf)
    limit = 20
    bgp.maxas_limit = limit
    assert_equal(limit, bgp.maxas_limit, "vrf #{vrf}: maxas-limit invalid")

    limit = bgp.default_maxas_limit
    bgp.maxas_limit = limit
    assert_equal(limit, bgp.maxas_limit, "vrf #{vrf}: maxas-limit not default")
  end

  def test_maxas_limit
    %w(default cyan).each do |vrf|
      maxas_limit(vrf)
    end
  end

  def test_neighbor_down_fib_accelerate
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
      bgp.neighbor_down_fib_accelerate = true
      assert(bgp.neighbor_down_fib_accelerate,
             "vrf #{vrf}: bgp neighbor_down_fib_accelerate should be enabled")
      bgp.neighbor_down_fib_accelerate = false
      refute(bgp.neighbor_down_fib_accelerate,
             "vrf #{vrf}: bgp neighbor_down_fib_accelerate should be disabled")
      bgp.destroy
    end
  end

  def test_neighbor_down_fib_accelerate_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.neighbor_down_fib_accelerate,
           'bgp neighbor_down_fib_accelerate should be disabled')
    bgp.destroy
  end

  def test_default_neighbor_down_fib_accelerate
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_neighbor_down_fib_accelerate,
           'bgp neighbor_down_fib_accelerate default value should be false')
    bgp.destroy
  end

  def test_reconnect_interval
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

  def test_reconnect_interval_default
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(bgp.default_reconnect_interval, bgp.reconnect_interval,
                 'reconnect_interval should be set to default value')
    bgp.destroy
  end

  def test_route_distinguisher
    remove_all_vrfs

    bgp = RouterBgp.new(55, 'blue')
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
  end

  def test_router_id
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
      bgp.router_id = '1.2.3.4'
      assert_equal('1.2.3.4', bgp.router_id,
                   "vrf #{vrf}: bgp router_id should be set to '1.2.3.4'")
      bgp.router_id = ''
      assert_empty(bgp.router_id,
                   "vrf #{vrf}: bgp router_id should *NOT* be configured")
      bgp.destroy
    end
  end

  def test_router_id_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.router_id,
                 'bgp router_id should *NOT* be configured')
    bgp.destroy
  end

  def test_default_router_id
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_empty(bgp.default_router_id,
                 'bgp router_id default value should be empty')
    bgp.destroy
  end

  def test_shutdown
    # NOTE: Shutdown command only applies under
    # default vrf
    asnum = 55
    bgp = RouterBgp.new(asnum)
    bgp.shutdown = true
    assert(bgp.shutdown, 'bgp should be shutdown')
    bgp.shutdown = false
    refute(bgp.shutdown, "bgp should in 'no shutdown' state")
    bgp.destroy
  end

  def test_shutdown_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.shutdown,
           "bgp should be in 'no shutdown' state")
    bgp.destroy
  end

  def test_default_shutdown
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_shutdown,
           'bgp shutdown default value should be false')
    bgp.destroy
  end

  def test_suppress_fib_pending
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

  def test_suppress_fib_pending_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.suppress_fib_pending,
           'bgp suppress_fib_pending should be disabled')
    bgp.destroy
  end

  def test_default_suppress_fib_pending
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_suppress_fib_pending,
           'bgp suppress_fib_pending default value should be false')
    bgp.destroy
  end

  def test_timer_bestpath_limit
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

  def test_timer_bestpath_limit_default
    asnum = 55
    bgp = RouterBgp.new(asnum)
    assert_equal(300, bgp.timer_bestpath_limit,
                 "timer_bestpath_limit should be default value of '300'")
    bgp.destroy
  end

  def test_timer_bestpath_limit_always
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

  def test_timer_bestpath_limit_always_not_configured
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.timer_bestpath_limit_always,
           'bgp timer_bestpath_limit_always should be disabled')
    bgp.destroy
  end

  def test_default_timer_bestpath_limit_always
    asnum = 55
    bgp = RouterBgp.new(asnum)
    refute(bgp.default_timer_bestpath_limit_always,
           'bgp timer_bestpath_limit_always default value should be false')
    bgp.destroy
  end

  def test_timer_bgp_keepalive_hold
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

  def test_default_timer_keepalive_hold_default
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
