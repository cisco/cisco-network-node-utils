# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/router_ospf'
require_relative '../lib/cisco_node_utils/router_ospf_vrf'

# TestRouterOspfVrf - Minitest for RouterOspfVrf node utility class
class TestRouterOspfVrf < CiscoTestCase
  def setup
    # Disable feature ospf before each test to ensure we
    # are starting with a clean slate for each test.
    super
    config('no feature ospf')
  end

  def teardown
    config('no feature ospf')
    super
  end

  def assert_match_vrf_line(routername, vrfname, cmd=nil)
    match_vrf_line(routername, vrfname, cmd, true)
  end

  def refute_match_vrf_line(routername, vrfname, cmd=nil)
    match_vrf_line(routername, vrfname, cmd, false)
  end

  def match_vrf_line(routername, vrfname, cmd=nil, match_cmd=true)
    s = @device.cmd('show run ospf all | sec "router ospf" | no-more')
    pattern = /router ospf #{routername}/
    assert_match(pattern, s)
    vrf_found = false
    # If no vrf or cmd, just finding the router is enough
    return true if vrfname == 'default' && cmd.nil?

    # Else, look for the vrf and/or cmd
    pattern.match(s).post_match.each_line do |line|
      # Skip blank lines
      next if /^\s*$/.match(line)
      if !vrf_found && vrfname != 'default'
        # Have to find the VRF before checking for cmd
        assert_match(/^\s+(.*)/, line,
                     "Exited 'router ospf #{routername}' submode "\
                     "before finding 'vrf #{vrfname}'. Output:\n#{s}")
        vrf_found = true if /vrf\s#{vrfname}/ =~ line
        return true if cmd.nil?
        next
      end

      # If we get here, either we found the VRF we want or we want no VRF
      if !match_cmd
        # If we find a new VRF, we're done
        return true if /vrf\s.*/ =~ line
        # Fail if we find the unwanted command
        refute_match(cmd, line)
      else
        # Fail if we hit a VRF before finding our cmd
        refute_match(/vrf\s.*/, line,
                     "Found vrf line before finding #{cmd} under vrf default")
        # We're done if we found the command
        return true if cmd =~ line
      end
    end
    if !vrf_found && vrfname != 'default'
      flunk("Ran out of output before finding 'vrf #{vrfname}':\n#{s}")
    elsif cmd && match_cmd
      flunk("Ran out of output before finding #{cmd}:\n#{s}")
    end
  end

  def create_routerospf(ospfname='ospfTest')
    RouterOspf.new(ospfname)
  end

  def create_routerospfvrf(router='Wolfpack', name='default')
    RouterOspfVrf.new(router, name)
  end

  def config_from_hash(hash)
    config('feature ospf')
    cfg = []
    hash.each do |k, v|
      # Assuming all values are in hash
      cfg << "router ospf #{k}"
      v.each do |k1, v1|
        cfg << "vrf #{v1[:vrf]}" if (k1 != 'default')
        cfg << "auto-cost reference-bandwidth #{v1[:cov]}"
        cfg << "default-metric #{v1[:dm]}"
        cfg << "router-id #{v1[:id]}"
        cfg << "timers throttle lsa #{v1[:l1]} #{v1[:l2]} #{v1[:l3]}"
        cfg << "timers throttle spf #{v1[:s1]} #{v1[:s2]} #{v1[:s3]}"
      end
    end
    config(*cfg)
  end

  def test_routerospfvrf_collection_size
    create_routerospfvrf('green')
    vrfs = RouterOspfVrf.vrfs
    assert_equal(1, vrfs.size, 'Error: Collection is not one')
    create_routerospfvrf('green', 'NC_State')
    vrfs = RouterOspfVrf.vrfs
    assert_equal(2, vrfs['green'].size, 'Error: Collection is not two')
    create_routerospfvrf('green', 'Duke')
    create_routerospfvrf('green', 'Carolina')
    vrfs = RouterOspfVrf.vrfs
    assert_equal(4, vrfs['green'].size, 'Error: Collection is not four')
    RouterOspf.routers.each_value(&:destroy)
    vrfs = RouterOspfVrf.vrfs
    assert_empty(vrfs, 'Error: Collection is not empty')
  end

  # rubocop:disable Style/AlignHash
  MULTIPLE_OSPFS = Hash.new { |h, k| h[k] = {} }.merge(
    'ospfTest' => {
      'default' => {
        vrf: 'default', cov: 90,
        cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 15_000,
        id: '9.0.0.2', l1: 130, l2: 530, l3: 1030, s1: 300,
        s2: 600, s3: 1100
      }
    },
    'bxb300' => {
      'default' => {
        vrf: 'default', cov: 200,
        cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 10_000,
        id: '10.0.0.3', l1: 130, l2: 530, l3: 1030, s1: 300,
        s2: 600, s3: 1100
      }
    },
  )
  # rubocop:enable Style/AlignHash

  def test_routerospfvrf_collection_not_empty_valid
    # pre-populate values
    config_from_hash(MULTIPLE_OSPFS)

    routers = RouterOspf.routers
    # validate the collection
    routers.each_key do |routername|
      vrfs = RouterOspfVrf.vrfs
      refute_empty(vrfs, 'Error: Collection is empty')
      hv = MULTIPLE_OSPFS.fetch(routername.to_s)
      next if hv.nil?
      hv = hv['default']
      vrfs[routername].each_value do |vrf|
        auto_cost_value = [] << hv[:cov] << hv[:cot]
        assert_equal(hv[:vrf], vrf.name,
                     'Error: Collection, vrf name')
        assert_equal(auto_cost_value, vrf.auto_cost,
                     'Error: Collection, auto cost')
        assert_equal(hv[:dm], vrf.default_metric,
                     'Error: Collection, default metric')
        assert_equal(hv[:id], vrf.router_id,
                     'Error: Collection, router id')
        lsa = [] << hv[:l1] << hv[:l2] << hv[:l3]
        assert_equal(lsa, vrf.timer_throttle_lsa,
                     'Error: Collection, timer throttle lsa')
        spf = [] << hv[:s1] << hv[:s2] << hv[:s3]
        assert_equal(spf, vrf.timer_throttle_spf,
                     'Error: Collection, timer throttle spf')
      end
    end
  end

  def test_routerospfvrf_create_vrf_nil
    assert_raises(TypeError) { RouterOspfVrf.new(nil, 'testvrf') }
  end

  def test_routerospfvrf_create_name_zero_length
    routerospf = RouterOspf.new('testOspf')
    assert_raises(ArgumentError) do
      RouterOspfVrf.new('testOspf', '')
    end
    routerospf.destroy
  end

  def test_routerospfvrf_create_valid
    ospfname = 'ospfTest'
    # routerospf = RouterOspf.new(ospfname)
    vrfname = 'default'
    vrf = RouterOspfVrf.new(ospfname, vrfname)
    assert_match_vrf_line(ospfname, vrfname)
    assert_equal(vrfname, vrf.name,
                 "Error: #{vrfname} vrf, create failed")
    vrf.parent.destroy
  end

  def test_routerospfvrf_get_parent_name
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    assert_equal(routerospf.name, vrf.parent.name,
                 'Error: Parent value is not correct')
    routerospf.destroy
  end

  def test_routerospfvrf_get_name
    vrfname = 'default'
    vrf = create_routerospfvrf('green')
    assert_match_vrf_line('green', vrfname)
    assert_equal(vrfname, vrf.name,
                 "Error: #{vrfname} vrf, name get value mismatch")
    vrf.parent.destroy
  end

  def test_routerospfvrf_destroy
    vrfname = 'default'
    vrf = create_routerospfvrf
    assert_raises(RuntimeError) do
      vrf.destroy
    end
    assert_match_vrf_line(vrf.parent.name, vrfname)
    vrf.parent.destroy
  end

  def test_routerospfvrf_auto_cost
    vrf = create_routerospfvrf
    auto_cost_value = [400_000, RouterOspfVrf::OSPF_AUTO_COST[:mbps]]
    # set auto-cost
    vrf.auto_cost_set(auto_cost_value[0], :mbps)
    pattern = /\s+auto-cost reference-bandwidth #{auto_cost_value[0]}/
    assert_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    assert_equal(auto_cost_value, vrf.auto_cost,
                 'Error: auto-cost, get value mismatch')
    vrf.parent.destroy
  end

  def test_routerospfvrf_auto_cost_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    auto_cost_value = [600_000, RouterOspfVrf::OSPF_AUTO_COST[:mbps]]
    # set auto-cost
    vrf.auto_cost_set(auto_cost_value[0], :mbps)
    pattern = /\s+auto-cost reference-bandwidth #{auto_cost_value[0]}/
    assert_match_vrf_line(routerospf.name, vrf.name, pattern)
    assert_equal(auto_cost_value, vrf.auto_cost,
                 "Error: #{vrf.name} vrf, auto-cost get value mismatch")

    # vrf 1
    auto_cost_value = [500_000, RouterOspfVrf::OSPF_AUTO_COST[:mbps]]
    # set cost
    vrf1.auto_cost_set(auto_cost_value[0], :mbps)
    pattern = /\s+auto-cost reference-bandwidth #{auto_cost_value[0]}/
    assert_match_vrf_line(routerospf.name, vrf1.name, pattern)
    assert_equal(auto_cost_value, vrf1.auto_cost,
                 "Error: #{vrf1.name} vrf, auto-cost get value mismatch")
    routerospf.destroy
  end

  def test_routerospfvrf_get_default_auto_cost
    vrf = create_routerospfvrf
    # NXOS specific
    auto_cost_value = [40, RouterOspfVrf::OSPF_AUTO_COST[:gbps]]
    assert_equal(auto_cost_value, vrf.default_auto_cost,
                 'Error: default auto-cost get value mismatch')
    assert_equal(auto_cost_value, vrf.auto_cost,
                 'Error: auto-cost get value default mismatch')
    vrf.parent.destroy
  end

  def test_routerospfvrf_default_metric
    vrf = create_routerospfvrf
    metric = 30_000
    vrf.default_metric = metric
    pattern = /\s+default-metric #{metric}/
    assert_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    assert_equal(metric, vrf.default_metric,
                 "Error: #{vrf.name} vrf, default-metric get value mismatch")
    # set default metric
    vrf.default_metric = vrf.default_default_metric
    refute_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    vrf.parent.destroy
  end

  def test_routerospfvrf_default_metric_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    metric = 35_000
    # set metric
    vrf.default_metric = metric
    pattern = /\s+default-metric #{metric}/
    assert_match_vrf_line(routerospf.name, vrf.name, pattern)
    assert_equal(metric, vrf.default_metric,
                 "Error: #{vrf.name} vrf, default-metric get value mismatch")

    # vrf 1
    metric = 25_000
    vrf1.default_metric = metric
    pattern = /\s+default-metric #{metric}/
    assert_match_vrf_line(routerospf.name, vrf1.name, pattern)
    assert_equal(metric, vrf1.default_metric,
                 "Error: #{vrf1.name} vrf, default-metric get value mismatch")

    routerospf.destroy
  end

  def test_routerospfvrf_log_adjacency_changes
    vrf = create_routerospfvrf

    assert_equal(:none, vrf.log_adjacency,
                 'Error: log-adjacency get value mismatch')

    vrf.log_adjacency = :log
    pattern = /\s+log-adjacency-changes/
    assert_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    assert_equal(:log, vrf.log_adjacency,
                 'Error: log-adjacency get value mismatch')

    vrf.log_adjacency = :detail
    pattern = /\s+log-adjacency-changes detail/
    assert_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    assert_equal(:detail, vrf.log_adjacency,
                 "Error: #{vrf.name} vrf, " \
                 'log-adjacency detail get value mismatch')

    # set default log adjacency
    vrf.log_adjacency = vrf.default_log_adjacency
    pattern = /\s+log-adjacency-changes(.*)/
    refute_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    vrf.parent.destroy
  end

  def test_routerospfvrf_log_adjacency_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    # set log_adjacency
    vrf.log_adjacency = :log
    pattern = /\s+log-adjacency-changes/
    assert_match_vrf_line(routerospf.name, vrf.name, pattern)
    assert_equal(:log, vrf.log_adjacency,
                 "Error: #{vrf.name} vrf, log-adjacency get value mismatch")

    # vrf 1
    # set log_adjacency
    vrf1.log_adjacency = :detail
    pattern = /\s+log-adjacency-changes/
    assert_match_vrf_line(routerospf.name, vrf1.name, pattern)
    assert_equal(:detail, vrf1.log_adjacency,
                 "Error: #{vrf1.name} vrf, log-adjacency get value mismatch")

    routerospf.destroy
  end

  def test_routerospfvrf_log_adjacency_multiple_vrf_2
    routerospf = create_routerospf
    vrf_default = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    # DO NOT set log_adjacency for default vrf
    # DO set log_adjacency for non-default vrf
    # set log_adjacency
    vrf1.log_adjacency = :detail
    pattern = /\s+log-adjacency-changes/
    assert_match_vrf_line(routerospf.name, vrf1.name, pattern)
    assert_equal(:detail, vrf1.log_adjacency,
                 "Error: #{vrf1.name} vrf, log-adjacency get value mismatch")

    # Make sure default vrf is set to :none
    assert_equal(:none, vrf_default.log_adjacency,
                 "Error: #{vrf_default.name} vrf_default, " \
                 'log-adjacency get value mismatch')

    routerospf.destroy
  end

  def test_routerospfvrf_router_id
    vrf = create_routerospfvrf
    id = '8.1.1.3'
    vrf.router_id = id
    pattern = /\s+router-id #{id}/
    assert_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    assert_equal(id, vrf.router_id,
                 "Error: #{vrf.name} vrf, router-id get value mismatch")
    # set default router id
    vrf.router_id = vrf.default_router_id
    refute_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    vrf.parent.destroy
  end

  def test_routerospfvrf_router_id_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    id = '8.1.1.3'
    # set id
    vrf.router_id = id
    pattern = /\s+router-id #{id}/
    assert_match_vrf_line(routerospf.name, vrf.name, pattern)
    assert_equal(id, vrf.router_id,
                 "Error: #{vrf.name} vrf, router-id get value mismatch")

    # vrf 1
    id = '10.1.1.3'
    # set id
    vrf1.router_id = id
    pattern = /\s+router-id #{id}/
    assert_match_vrf_line(routerospf.name, vrf1.name, pattern)
    assert_equal(id, vrf1.router_id,
                 "Error: #{vrf1.name} vrf, router-id get value mismatch")

    routerospf.destroy
  end

  def test_routerospfvrf_timer_throttle_lsa
    vrf = create_routerospfvrf
    lsa = [] << 100 << 500 << 1000
    vrf.timer_throttle_lsa_set(lsa[0], lsa[1], lsa[2])
    # vrf.send(:timer_throttle_lsa=, lsa[0], lsa[1], lsa[2])
    pattern = /\s+timers throttle lsa #{lsa[0]} #{lsa[1]} #{lsa[2]}/
    assert_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    assert_equal(lsa, vrf.timer_throttle_lsa,
                 "Error: #{vrf.name} vrf, timer throttle lsa " \
                 'get values mismatch')
    vrf.parent.destroy
  end

  def test_routerospfvrf_timer_throttle_lsa_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    lsa = [] << 100 << 500 << 1000
    # set lsa
    vrf.timer_throttle_lsa_set(lsa[0], lsa[1], lsa[2])
    # vrf.send(:timer_throttle_lsa=, lsa[0], lsa[1], lsa[2])
    pattern = /\s+timers throttle lsa #{lsa[0]} #{lsa[1]} #{lsa[2]}/
    assert_match_vrf_line(routerospf.name, vrf.name, pattern)
    assert_equal(lsa, vrf.timer_throttle_lsa,
                 "Error: #{vrf.name} vrf, timer throttle lsa " \
                 'get values mismatch')

    lsa = [] << 300 << 700 << 2000
    # set lsa
    vrf1.timer_throttle_lsa_set(lsa[0], lsa[1], lsa[2])
    # vrf1.send(:timer_throttle_lsa=, lsa[0], lsa[1], lsa[2])
    pattern = /\s+timers throttle lsa #{lsa[0]} #{lsa[1]} #{lsa[2]}/
    assert_match_vrf_line(routerospf.name, vrf1.name, pattern)
    assert_equal(lsa, vrf1.timer_throttle_lsa,
                 "Error: #{vrf1.name} vrf, timer throttle lsa " \
                 'get values mismatch')

    routerospf.destroy
  end

  def test_routerospfvrf_get_default_timer_throttle_lsa
    vrf = create_routerospfvrf
    lsa = [0, 5000, 5000]
    assert_equal(lsa[0], vrf.timer_throttle_lsa_start,
                 "Error: #{vrf.name} vrf, timer throttle lsa start not correct")
    assert_equal(lsa[1], vrf.timer_throttle_lsa_hold,
                 "Error: #{vrf.name} vrf, timer throttle lsa hold not correct")
    assert_equal(lsa[2], vrf.timer_throttle_lsa_max,
                 "Error: #{vrf.name} vrf, timer throttle lsa max not correct")
    assert_equal(lsa[0], vrf.default_timer_throttle_lsa_start,
                 'Error: default timer throttle lsa start not correct')
    assert_equal(lsa[1], vrf.default_timer_throttle_lsa_hold,
                 'Error: default timer throttle lsa hold not correct')
    assert_equal(lsa[2], vrf.default_timer_throttle_lsa_max,
                 'Error: default timer throttle lsa max not correct')
    vrf.parent.destroy
  end

  def test_routerospfvrf_timer_throttle_spf
    vrf = create_routerospfvrf
    spf = [250, 500, 1000]
    # vrf.send(:timer_throttle_spf=, spf[0], spf[1], spf[2])
    vrf.timer_throttle_spf_set(spf[0], spf[1], spf[2])
    pattern = /\s+timers throttle spf #{spf[0]} #{spf[1]} #{spf[2]}/
    assert_match_vrf_line(vrf.parent.name, vrf.name, pattern)
    assert_equal(spf, vrf.timer_throttle_spf,
                 "Error: #{vrf.name} vrf, timer throttle spf " \
                 'get values mismatch')
    vrf.parent.destroy
  end

  def test_routerospfvrf_timer_throttle_spf_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    spf = [] << 250 << 500 << 1000
    # set spf
    vrf.timer_throttle_spf_set(spf[0], spf[1], spf[2])
    # vrf.send(:timer_throttle_spf=, spf[0], spf[1], spf[2])
    pattern = /\s+timers throttle spf #{spf[0]} #{spf[1]} #{spf[2]}/
    assert_match_vrf_line(routerospf.name, vrf.name, pattern)
    assert_equal(spf, vrf.timer_throttle_spf,
                 "Error: #{vrf.name} vrf, timer throttle spf " \
                 'get values mismatch')

    spf = [] << 300 << 700 << 2000
    # set spf
    vrf1.timer_throttle_spf_set(spf[0], spf[1], spf[2])
    # vrf1.send(:timer_throttle_spf=, spf[0], spf[1], spf[2])
    pattern = /\s+timers throttle spf #{spf[0]} #{spf[1]} #{spf[2]}/
    assert_match_vrf_line(routerospf.name, vrf1.name, pattern)
    assert_equal(spf, vrf1.timer_throttle_spf,
                 "Error: #{vrf1.name} vrf, timer throttle spf " \
                 'get values mismatch')

    routerospf.destroy
  end

  def test_routerospfvrf_get_default_timer_throttle_spf
    vrf = create_routerospfvrf
    spf = [200, 1000, 5000]
    assert_equal(spf[0], vrf.default_timer_throttle_spf_start,
                 'Error: default timer throttle spf not correct')
    assert_equal(spf[1], vrf.default_timer_throttle_spf_hold,
                 'Error: default timer throttle hold not correct')
    assert_equal(spf[2], vrf.default_timer_throttle_spf_max,
                 'Error: default timer throttle max not correct')
    assert_equal(spf[0], vrf.timer_throttle_spf_start,
                 "Error: #{vrf.name} vrf, " \
                 'default timer throttle spf not correct')
    assert_equal(spf[1], vrf.timer_throttle_spf_hold,
                 "Error: #{vrf.name} vrf, " \
                 'default timer throttle hold not correct')
    assert_equal(spf[2], vrf.timer_throttle_spf_max,
                 "Error: #{vrf.name} vrf, " \
                 'default timer throttle max not correct')
    vrf.parent.destroy
  end

  def test_routerospfvrf_create_valid_destroy_default
    ospfname = 'ospfTest'
    routerospf = RouterOspf.new(ospfname)
    vrfname = 'default'
    vrf = RouterOspfVrf.new(routerospf.name, vrfname)
    assert_match_vrf_line(ospfname, vrfname)
    assert_equal(vrfname, vrf.name,
                 "Error: #{vrfname} vrf, create failed")
    assert_raises(RuntimeError) do
      vrf.destroy
    end
    routerospf.destroy
  end

  # rubocop:disable Style/AlignHash
  MULTIPLE_OSPFS_MULTIPLE_VRFS = Hash.new { |h, k| h[k] = {} }.merge(
    'ospfTest' => {
      'default' => {
        vrf: 'default', cov: 90,
        cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 15_000,
        id: '9.0.0.2', l1: 130, l2: 530, l3: 1030, s1: 300,
        s2: 600, s3: 1100
      }
    },
    'bxb300' => {
      'default' => {
        vrf: 'default', cov: 200,
        cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 10_000,
        id: '10.0.0.3', l1: 130, l2: 530, l3: 1030, s1: 300,
        s2: 600, s3: 1100
      },
      'nondefault' => {
        vrf: 'nondefault', cov: 300,
        cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 30_000,
        id: '10.0.0.4', l1: 230, l2: 730, l3: 2030, s1: 400,
        s2: 700, s3: 2100
      },
    },
  )
  # rubocop:enable Style/AlignHash

  def test_routerospfvrf_collection_router_multi_vrfs
    config_from_hash(MULTIPLE_OSPFS_MULTIPLE_VRFS)
    routers = RouterOspf.routers
    # validate the collection
    routers.each_key do |routername|
      vrfs = RouterOspfVrf.vrfs
      refute_empty(vrfs, 'Error: Collection is empty')
      unless MULTIPLE_OSPFS_MULTIPLE_VRFS.key?(routername)
        puts "%Error: hash does not have hash key #{routername}"
      end
      ospfh = MULTIPLE_OSPFS_MULTIPLE_VRFS.fetch(routername)
      vrfs[routername].each do |name, vrf|
        puts "%Error: hash key #{routername} not found" unless ospfh.key?(name)
        hv = ospfh.fetch(name)
        auto_cost_value = [] << hv[:cov] << hv[:cot]
        assert_equal(hv[:vrf], vrf.name,
                     'Error: Collection, vrf name')
        assert_equal(auto_cost_value, vrf.auto_cost,
                     'Error: Collection, auto cost')
        assert_equal(hv[:dm], vrf.default_metric,
                     'Error: Collection, default metric')
        assert_equal(hv[:id], vrf.router_id,
                     'Error: Collection, router id')
        lsa = [] << hv[:l1] << hv[:l2] << hv[:l3]
        assert_equal(lsa, vrf.timer_throttle_lsa,
                     'Error: Collection, timer throttle lsa')
        spf = [] << hv[:s1] << hv[:s2] << hv[:s3]
        assert_equal(spf, vrf.timer_throttle_spf,
                     'Error: Collection, timer throttle spf')
      end
    end
  end

  def test_routerospfvrf_timer_throttle_lsa_start_hold_max
    vrf = create_routerospfvrf
    vrf.timer_throttle_lsa_set(250, 900, 5001)
    assert_equal(250, vrf.timer_throttle_lsa_start,
                 "Error: #{vrf.name} vrf, start timer throttle lsa not correct")
    assert_equal(900, vrf.timer_throttle_lsa_hold,
                 "Error: #{vrf.name} vrf, hold timer throttle lsa not correct")
    assert_equal(5001, vrf.timer_throttle_lsa_max,
                 "Error: #{vrf.name} vrf, max timer throttle lsa not correct")
    vrf.parent.destroy
  end

  def test_routerospfvrf_timer_throttle_spf_start_hold_max
    vrf = create_routerospfvrf
    vrf.timer_throttle_spf_set(250, 900, 5001)
    assert_equal(250, vrf.timer_throttle_spf_start,
                 "Error: #{vrf.name} vrf, start timer throttle spf not correct")
    assert_equal(900, vrf.timer_throttle_spf_hold,
                 "Error: #{vrf.name} vrf, hold timer throttle spf not correct")
    assert_equal(5001, vrf.timer_throttle_spf_max,
                 "Error: #{vrf.name} vrf, max timer throttle spf not correct")
    vrf.parent.destroy
  end

  def test_routerospfvrf_noninstantiated
    routerospf = create_routerospf
    vrf = RouterOspfVrf.new('absent', 'absent', false)
    vrf.auto_cost
    vrf.default_metric
    vrf.log_adjacency
    vrf.router_id
    vrf.timer_throttle_lsa
    vrf.timer_throttle_spf
    routerospf.destroy
  end
end
