# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/router_ospf', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/router_ospf_vrf', __FILE__)

# TestRouterOspfVrf - Minitest for RouterOspfVrf node utility class
class TestRouterOspfVrf < CiscoTestCase
  def setup
    # Disable feature ospf before each test to ensure we
    # are starting with a clean slate for each test.
    super
    @device.cmd('configure terminal')
    @device.cmd('no feature ospf')
    @device.cmd('end')
    node.cache_flush
  end

  # @option routers [Cisco::RouterOspf] list of objects
  def ospf_routers_destroy(routers)
    routers.each_value(&:destroy)
  end

  # @option vrfs [Cisco::RouterOspfVrf] list of objects
  # @option routername [String] ospf instance name
  def ospf_vrfs_destroy(vrfs, routername)
    vrfs[routername].each_value { |vrf| vrf.destroy if vrf.name != 'default' }
  end

  def get_routerospfvrf_match_line(router, vrfname)
    s = @device.cmd('show run all | no-more')
    cmd = 'router ospf'
    pattern = /#{cmd}\s#{router}/
    # no match found, return nil
    return nil if (md = pattern.match(s)).nil?

    # match found but default vrf
    return 'default' if (vrfname == 'default')

    # assign post match
    s = md.post_match
    # non default case, check vf exist
    s.each_line do |line|
      next unless (/^\s+$/).match(line).nil?

      # check whether we in 2 space
      ml = (/^\s+(.*)/).match(line)
      return nil if ml.nil?

      # check wether we found vrf
      ml = (/vrf\s#{vrfname}/).match(line)
      return ml unless ml.nil?
    end # s.each
  end

  def get_routerospfvrf_match_submode_line(router, vrfname, mtline)
    s = @device.cmd('show run all | no-more')
    cmd = 'router ospf'
    pattern = /#{cmd}\s#{router}/
    vrf_found = false

    # no match found, return nil
    return nil if (md = pattern.match(s)).nil?
    s = md.post_match
    # match found, so loop through the config and
    # find appropriate default or exact vrf
    s.each_line do |line|
      # if line is empty then move on to next line
      next unless (/^\s+$/).match(line).nil?

      # check whether we in 2 space
      ml = (/^\s+(.*)/).match(line)
      return nil if ml.nil?

      # for default vrf we do not expect any vrfname present
      # on the device, hence return nil.
      if (vrfname == 'default')
        ml = (/vrf\s(.*)$/).match(line)
        return nil unless ml.nil?
      else
        # for non-default vrf, find the match if not find one
        if vrf_found == false
          ml = (/vrf\s#{vrfname}/).match(line)
          next if ml.nil?
          vrf_found = true
        else
          # This is new vrf, hence return nil
          ml = (/vrf\s(.*)$/).match(line)
          return nil unless ml.nil?
        end
      end

      # if match found then return line
      ml = mtline.match(line)
      return ml unless ml.nil?
    end # s.each
  end

  def example_test_match_line
    puts "vrf 1: #{get_routerospfvrf_match_line('ospfTest', 'default')}"
    puts 'next vrf!!!!!!!!!!!!!'
    puts "vrf 2: #{get_routerospfvrf_match_line('TestOSPF', 'vrftest')}"
    puts 'next vrf!!!!!!!!!!!!!'
    puts "vrf 3: #{get_routerospfvrf_match_line('TestOSPF', 'testvrf')}"
    puts 'next vrf!!!!!!!!!!!!!'
    puts "vrf 4: #{get_routerospfvrf_match_line('ospfTest', 'testvrf')}"
  end

  def example_test_match_submode_line
    pattern = (/\s+timers throttle lsa (.*)/)
    puts "vrf submode timer lsa: #{get_routerospfvrf_match_submode_line('ospfTest', 'default', pattern)}"
    puts "vrf submode timer lsa: #{get_routerospfvrf_match_submode_line('TestOSPF', 'vrftest1', pattern)}"
    puts "vrf submode timer spf1: #{get_routerospfvrf_match_submode_line('ospftest', 'vrftest', pattern)}"
    pattern = (/\s+router-id (.*)/)
    puts "vrf submode: #{get_routerospfvrf_match_submode_line('ospfTest', 'testvrf', pattern)}"
  end

  def create_routerospf(ospfname='ospfTest')
    RouterOspf.new(ospfname)
  end

  def create_routerospfvrf(router='Wolfpack', name='default')
    RouterOspfVrf.new(router, name)
  end

  def test_routerospfvrf_collection_size
    create_routerospfvrf('green')
    vrfs = RouterOspfVrf.vrfs
    assert_equal(1, vrfs.size,
                 'Error: Collection is not one')
    create_routerospfvrf('green', 'NC_State')
    vrfs = RouterOspfVrf.vrfs
    assert_equal(2, vrfs['green'].size,
                 'Error: Collection is not two')
    create_routerospfvrf('green', 'Duke')
    create_routerospfvrf('green', 'Carolina')
    vrfs = RouterOspfVrf.vrfs
    assert_equal(4, vrfs['green'].size,
                 'Error: Collection is not four')
    ospf_routers_destroy(RouterOspf.routers)
    vrfs = RouterOspfVrf.vrfs
    assert_equal(0, vrfs.size,
                 'Error: Collection is not zero')
  end

  def test_routerospfvrf_collection_not_empty_valid
    ospf_h = Hash.new { |h, k| h[k] = {} }
    ospf_h['ospfTest'] = {
      vrf: 'default', cov: 90,
      cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 15_000,
      id: '9.0.0.2', l1: 130, l2: 530, l3: 1030, s1: 300,
      s2: 600, s3: 1100
    }
    ospf_h['bxb300'] = {
      vrf: 'default', cov: 200,
      cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 10_000,
      id: '10.0.0.3', l1: 130, l2: 530, l3: 1030, s1: 300,
      s2: 600, s3: 1100
    }
    # pre-populate values
    ospf_h.each do |k, v|
      # Assuming all values are in hash
      @device.cmd('configure terminal')
      @device.cmd('feature ospf')
      @device.cmd("router ospf #{k}")
      @device.cmd("vrf #{v[:vrf]}")
      @device.cmd("auto-cost reference-bandwidth #{v[:cov]}")
      @device.cmd("default-metric #{v[:dm]}")
      @device.cmd("router-id #{v[:id]}")
      @device.cmd("timers throttle lsa #{v[:l1]} #{v[:l2]} #{v[:l3]}")
      @device.cmd("timers throttle spf #{v[:s1]} #{v[:s2]} #{v[:s3]}")
      @device.cmd('end')
      node.cache_flush
    end

    routers = RouterOspf.routers
    # validate the collection
    routers.each_key do |routername|
      vrfs = RouterOspfVrf.vrfs
      refute_empty(vrfs, 'Error: Collection is empty')
      hv = ospf_h.fetch(routername.to_s)
      next if hv.nil?
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
      ospf_vrfs_destroy(vrfs, routername)
    end
    ospf_routers_destroy(routers)
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
    line = get_routerospfvrf_match_line(ospfname, vrfname)
    refute_nil(line, "Error: #{vrfname} vrf, does not exist in CLI")
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
    line = get_routerospfvrf_match_line('green', vrfname)
    assert_equal(vrfname, line,
                 "Error: #{vrfname} vrf,name mismatch")
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
    line = get_routerospfvrf_match_line(vrf.parent.name, vrfname)
    assert_equal(vrfname, line,
                 "Error: #{vrfname} vrf, destroy failed")
    vrf.parent.destroy
  end

  def test_routerospfvrf_auto_cost
    vrf = create_routerospfvrf
    auto_cost_value = [400_000, RouterOspfVrf::OSPF_AUTO_COST[:mbps]]
    # set auto-cost
    vrf.auto_cost_set(auto_cost_value[0], :mbps)
    pattern = (/\s+auto-cost reference-bandwidth #{auto_cost_value[0]}/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    refute_nil(line, 'Error: auto-cost, missing in CLI')
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
    pattern = (/\s+auto-cost reference-bandwidth #{auto_cost_value[0]}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf.name, pattern)
    refute_nil(line, "Error: #{vrf.name} vrf, auto-cost missing in CLI")
    assert_equal(auto_cost_value, vrf.auto_cost,
                 "Error: #{vrf.name} vrf, auto-cost get value mismatch")

    # vrf 1
    auto_cost_value = [500_000, RouterOspfVrf::OSPF_AUTO_COST[:mbps]]
    pattern = (/\s+auto-cost reference-bandwidth #{auto_cost_value[0]}/)
    # set cost
    vrf1.auto_cost_set(auto_cost_value[0], :mbps)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf1.name, pattern)
    refute_nil(line, "Error: #{vrf1.name} vrf, auto-cost missing in CLI")
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
    pattern = (/\s+default-metric #{metric}/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    refute_nil(line, "Error: #{vrf.name} vrf, default-metric missing in CLI")
    assert_equal(metric, vrf.default_metric,
                 "Error: #{vrf.name} vrf, default-metric get value mismatch")
    # set default metric
    vrf.default_metric = vrf.default_default_metric
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    assert_nil(line,
               "Error: #{vrf.name}] vrf, default default-metric set failed")
    vrf.parent.destroy
  end

  def test_routerospfvrf_default_metric_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    metric = 35_000
    # set metric
    vrf.default_metric = metric
    pattern = (/\s+default-metric #{metric}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf.name, pattern)
    refute_nil(line, "Error: #{vrf.name} vrf, default-metric missing in CLI")
    assert_equal(metric, vrf.default_metric,
                 "Error: #{vrf.name} vrf, default-metric get value mismatch")

    # vrf 1
    metric = 25_000
    vrf1.default_metric = metric
    pattern = (/\s+default-metric #{metric}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf1.name, pattern)
    refute_nil(line, "Error: #{vrf1.name} vrf, default-metric missing in CLI")
    assert_equal(metric, vrf1.default_metric,
                 "Error: #{vrf1.name} vrf, default-metric get value mismatch")

    routerospf.destroy
  end

  def test_routerospfvrf_log_adjacency_changes
    vrf = create_routerospfvrf

    assert_equal(:none, vrf.log_adjacency,
                 'Error: log-adjacency get value mismatch')

    vrf.log_adjacency = :log
    pattern = (/\s+log-adjacency-changes/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    refute_nil(line, 'Error: log-adjacency missing in CLI')
    assert_equal(:log, vrf.log_adjacency,
                 'Error: log-adjacency get value mismatch')

    vrf.log_adjacency = :detail
    pattern = (/\s+log-adjacency-changes detail/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    refute_nil(line,
               "Error: #{vrf.name} vrf, log-adjacency detail missing in CLI")
    assert_equal(:detail, vrf.log_adjacency,
                 "Error: #{vrf.name} vrf, log-adjacency detail get value mismatch")

    # set default log adjacency
    vrf.log_adjacency = vrf.default_log_adjacency
    pattern = (/\s+log-adjacency-changes(.*)/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    assert_nil(line, "Error: #{vrf.name} vrf, default log-adjacency set failed")
    vrf.parent.destroy
  end

  def test_routerospfvrf_log_adjacency_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    # set log_adjacency
    vrf.log_adjacency = :log
    pattern = (/\s+log-adjacency-changes/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf.name, pattern)

    refute_nil(line, "Error: #{vrf.name} vrf, log-adjacency missing in CLI")
    assert_equal(:log, vrf.log_adjacency,
                 "Error: #{vrf.name} vrf, log-adjacency get value mismatch")

    # vrf 1
    # set log_adjacency
    vrf1.log_adjacency = :detail
    pattern = (/\s+log-adjacency-changes/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf1.name, pattern)

    refute_nil(line, "Error: #{vrf1.name} vrf, log-adjacency missing in CLI")
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
    pattern = (/\s+log-adjacency-changes/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf1.name, pattern)

    refute_nil(line, "Error: #{vrf1.name} vrf, log-adjacency missing in CLI")
    assert_equal(:detail, vrf1.log_adjacency,
                 "Error: #{vrf1.name} vrf, log-adjacency get value mismatch")

    # Make sure default vrf is set to :none
    assert_equal(:none, vrf_default.log_adjacency,
                 "Error: #{vrf_default.name} vrf_default, log-adjacency get value mismatch")

    routerospf.destroy
  end

  def test_routerospfvrf_router_id
    vrf = create_routerospfvrf
    id = '8.1.1.3'
    vrf.router_id = id
    pattern = (/\s+router-id #{id}/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    refute_nil(line, "Error: #{vrf.name} vrf, router-id missing in CLI")
    assert_equal(id, vrf.router_id,
                 "Error: #{vrf.name} vrf, router-id get value mismatch")
    # set default router id
    vrf.router_id = vrf.default_router_id
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    assert_nil(line, "Error: #{vrf.name} vrf, set default router-id failed")
    vrf.parent.destroy
  end

  def test_routerospfvrf_router_id_multiple_vrf
    routerospf = create_routerospf
    vrf = create_routerospfvrf(routerospf.name)
    vrf1 = create_routerospfvrf(routerospf.name, 'testvrf')
    id = '8.1.1.3'
    # set id
    vrf.router_id = id
    pattern = (/\s+router-id #{id}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf.name, pattern)
    refute_nil(line, "Error: #{vrf.name} vrf, router-id missing in CLI")
    assert_equal(id, vrf.router_id,
                 "Error: #{vrf.name} vrf, router-id get value mismatch")

    # vrf 1
    id = '10.1.1.3'
    # set id
    vrf1.router_id = id
    pattern = (/\s+router-id #{id}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf1.name, pattern)
    refute_nil(line, "Error: #{vrf1.name} vrf, router-id missing in CLI")
    assert_equal(id, vrf1.router_id,
                 "Error: #{vrf1.name} vrf, router-id get value mismatch")

    routerospf.destroy
  end

  def test_routerospfvrf_timer_throttle_lsa
    vrf = create_routerospfvrf
    lsa = [] << 100 << 500 << 1000
    vrf.timer_throttle_lsa_set(lsa[0], lsa[1], lsa[2])
    # vrf.send(:timer_throttle_lsa=, lsa[0], lsa[1], lsa[2])
    pattern = (/\s+timers throttle lsa #{lsa[0]} #{lsa[1]} #{lsa[2]}/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    refute_nil(line,
               "Error: #{vrf.name} vrf, timer throttle lsa missing in CLI")
    assert_equal(lsa, vrf.timer_throttle_lsa,
                 "Error: #{vrf.name} vrf, timer throttle lsa get values mismatch")
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
    pattern = (/\s+timers throttle lsa #{lsa[0]} #{lsa[1]} #{lsa[2]}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf.name, pattern)
    refute_nil(line,
               "Error: #{vrf.name} vrf, timer throttle lsa missing in CLI")
    assert_equal(lsa, vrf.timer_throttle_lsa,
                 "Error: #{vrf.name} vrf, timer throttle lsa get values mismatch")

    lsa = [] << 300 << 700 << 2000
    # set lsa
    vrf1.timer_throttle_lsa_set(lsa[0], lsa[1], lsa[2])
    # vrf1.send(:timer_throttle_lsa=, lsa[0], lsa[1], lsa[2])
    pattern = (/\s+timers throttle lsa #{lsa[0]} #{lsa[1]} #{lsa[2]}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf1.name, pattern)
    refute_nil(line,
               "Error: #{vrf1.name} vrf, timer throttle lsa missing in CLI")
    assert_equal(lsa, vrf1.timer_throttle_lsa,
                 "Error: #{vrf1.name} vrf, timer throttle lsa get values mismatch")

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
    pattern = (/\s+timers throttle spf #{spf[0]} #{spf[1]} #{spf[2]}/)
    line = get_routerospfvrf_match_submode_line(vrf.parent.name,
                                                vrf.name, pattern)
    refute_nil(line,
               "Error: #{vrf.name} vrf, timer throttle spf missing in CLI")
    assert_equal(spf, vrf.timer_throttle_spf,
                 "Error: #{vrf.name} vrf, timer throttle spf get values mismatch")
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
    pattern = (/\s+timers throttle spf #{spf[0]} #{spf[1]} #{spf[2]}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf.name, pattern)
    refute_nil(line,
               "Error: #{vrf.name} vrf, timer throttle spf missing in CLI")
    assert_equal(spf, vrf.timer_throttle_spf,
                 "Error: #{vrf.name} vrf, timer throttle spf get values mismatch")

    spf = [] << 300 << 700 << 2000
    # set spf
    vrf1.timer_throttle_spf_set(spf[0], spf[1], spf[2])
    # vrf1.send(:timer_throttle_spf=, spf[0], spf[1], spf[2])
    pattern = (/\s+timers throttle spf #{spf[0]} #{spf[1]} #{spf[2]}/)
    line = get_routerospfvrf_match_submode_line(routerospf.name,
                                                vrf1.name, pattern)
    refute_nil(line,
               "Error: #{vrf1.name} vrf, timer throttle spf missing in CLI")
    assert_equal(spf, vrf1.timer_throttle_spf,
                 "Error: #{vrf1.name} vrf, timer throttle spf get values mismatch")

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
                 "Error: #{vrf.name} vrf, default timer throttle spf not correct")
    assert_equal(spf[1], vrf.timer_throttle_spf_hold,
                 "Error: #{vrf.name} vrf, default timer throttle hold not correct")
    assert_equal(spf[2], vrf.timer_throttle_spf_max,
                 "Error: #{vrf.name} vrf, default timer throttle max not correct")
    vrf.parent.destroy
  end

  def test_routerospfvrf_create_valid_destroy_default
    ospfname = 'ospfTest'
    routerospf = RouterOspf.new(ospfname)
    vrfname = 'default'
    vrf = RouterOspfVrf.new(routerospf.name, vrfname)
    line = get_routerospfvrf_match_line(ospfname, vrfname)
    refute_nil(line, "Error: #{vrfname} vrf, does not exist in CLI")
    assert_equal(vrfname, vrf.name,
                 "Error: #{vrfname} vrf, create failed")
    assert_raises(RuntimeError) do
      vrf.destroy
    end
    routerospf.destroy
  end

  def test_routerospfvrf_collection_router_multi_vrfs
    ospf_h = Hash.new { |h, k| h[k] = {} }
    ospf_h['ospfTest'] = {
      'default' => {
        vrf: 'default', cov: 90,
        cot: RouterOspfVrf::OSPF_AUTO_COST[:mbps], dm: 15_000,
        id: '9.0.0.2', l1: 130, l2: 530, l3: 1030, s1: 300,
        s2: 600, s3: 1100
      },
    }

    # rubocop:disable Style/AlignHash
    ospf_h['bxb300'] = {
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
    }
    # rubocop:enable Style/AlignHash

    s = @device.cmd('configure terminal')
    s = @device.cmd('feature ospf')
    s = @device.cmd('end')
    # pre-populate values
    ospf_h.each do |k, v|
      # Assuming all values are in hash
      s = @device.cmd('configure terminal')
      s = @device.cmd("router ospf #{k}")
      v.each do |k1, v1|
        # puts "!!!!!k1: v1 vrf: #{k1} : !!!#{v1[:vrf]}"
        s = @device.cmd("vrf #{v1[:vrf]}") if (k1 != 'default')
        s = @device.cmd("auto-cost reference-bandwidth #{v1[:cov]}")
        s = @device.cmd("default-metric #{v1[:dm]}")
        s = @device.cmd("router-id #{v1[:id]}")
        s = @device.cmd("timers throttle lsa #{v1[:l1]} #{v1[:l2]} #{v1[:l3]}")
        s = @device.cmd("timers throttle spf #{v1[:s1]} #{v1[:s2]} #{v1[:s3]}")
        s = @device.cmd('exit') if (k1 != 'default')
      end
      s = @device.cmd('end')
    end
    node.cache_flush

    routers = RouterOspf.routers
    # validate the collection
    routers.each_key do |routername|
      vrfs = RouterOspfVrf.vrfs
      refute_empty(vrfs, 'Error: Collection is empty')
      puts "%Error: ospf_h does not have hash key #{routername}" unless ospf_h.key?(routername)
      ospfh = ospf_h.fetch(routername)
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
      ospf_vrfs_destroy(vrfs, routername)
    end
    ospf_routers_destroy(routers)
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
