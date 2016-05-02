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
require_relative '../lib/cisco_node_utils/vrf_af'

include Cisco

# TestVrfAf - Minitest for Vrf node utility class
class TestVrfAf < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    return unless @@pre_clean_needed
    nexus_feature_disable
    remove_all_vrfs
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    nexus_feature_disable
    remove_all_vrfs
    super
  end

  def nexus_feature_disable
    config('no feature bgp')

    # Some platforms complain when nv overlay is not configured
    config_no_warn('no nv overlay evpn')

    # Some platforms remove the 'evpn' command when 'no nv overlay evpn'
    # is processed, while others must remove it explicitly.
    config_no_warn('no evpn')
  end

  def test_create_destroy
    v1 = VrfAF.new('cyan', %w(ipv4 unicast))
    v2 = VrfAF.new('cyan', %w(ipv6 unicast))
    v3 = VrfAF.new('red', %w(ipv4 unicast))
    v4 = VrfAF.new('blue', %w(ipv4 unicast))
    v5 = VrfAF.new('red', %w(ipv6 unicast))
    assert_equal(2, VrfAF.afs['cyan'].keys.count)
    assert_equal(2, VrfAF.afs['red'].keys.count)
    assert_equal(1, VrfAF.afs['blue'].keys.count)

    v1.destroy
    v5.destroy
    assert_equal(1, VrfAF.afs['cyan'].keys.count)
    assert_equal(1, VrfAF.afs['red'].keys.count)
    assert_equal(1, VrfAF.afs['blue'].keys.count)

    v2.destroy
    v3.destroy
    v4.destroy
    assert_equal(0, VrfAF.afs['cyan'].keys.count)
    assert_equal(0, VrfAF.afs['red'].keys.count)
    assert_equal(0, VrfAF.afs['blue'].keys.count)
  end

  #-----------------------------------------
  # test_route_policy
  def test_route_policy
    config('route-policy abc', 'end-policy') if platform == :ios_xr
    [%w(ipv4 unicast), %w(ipv6 unicast)].each { |af| route_policy(af) }
    config('route-policy abc', 'end-policy') if platform == :ios_xr
  end

  def route_policy(af)
    v = VrfAF.new('black', af)

    assert_nil(v.default_route_policy_import,
               "Test1.1 : #{af} : route_policy_import")
    assert_nil(v.default_route_policy_export,
               "Test1.2 : #{af} : route_policy_export")
    opts = [:import, :export]
    # test route_target_import
    # test route_target_export
    opts.each do |opt|
      # test route_policy set, from nil to name
      policy_name = 'abc'
      v.send("route_policy_#{opt}=", policy_name)
      result = v.send("route_policy_#{opt}")
      assert_equal(policy_name, result,
                   "Test2.1 : #{af} : route_policy_#{opt}")

      # test route_policy remove, from name to nil
      policy_name = nil
      v.send("route_policy_#{opt}=", policy_name)
      result = v.send("route_policy_#{opt}")
      assert_nil(result, "Test2.2 : #{af} : route_policy_#{opt}")

      # test route_policy remove, from nil to nil
      v.send("route_policy_#{opt}=", policy_name)
      result = v.send("route_policy_#{opt}")
      assert_nil(result, "Test2.3 : #{af} : route_policy_#{opt}")
    end
    v.destroy
  end

  def test_route_target
    [%w(ipv4 unicast), %w(ipv6 unicast)].each { |af| route_target(af) }
  end

  def route_target(af)
    #
    # TBD: The evpn parts of this test need to check for compatible linecards to
    # skip the evpn portions. Don't use vxlan_linecard? as that will cause all
    # tests to be skipped.
    #
    # Common tester for route-target properties. Tests evpn and non-evpn.
    #   route_target_both_auto
    #   route_target_both_auto_evpn
    #   route_target_export
    #   route_target_export_evpn
    #   route_target_import
    #   route_target_import_evpn
    vrf = 'orange'
    v = VrfAF.new(vrf, af)

    # test route target both auto and route target both auto evpn
    refute(v.default_route_target_both_auto,
           'default value for route target both auto should be false')

    refute(v.default_route_target_both_auto_evpn,
           'default value for route target both auto evpn should be false')

    if validate_property_excluded?('vrf_af', 'route_target_both_auto')
      assert_raises(Cisco::UnsupportedError) { v.route_target_both_auto = true }
    else
      v.route_target_both_auto = true
      assert(v.route_target_both_auto, "vrf context #{vrf} af #{af}: "\
             'v route-target both auto should be enabled')

      v.route_target_both_auto = false
      refute(v.route_target_both_auto, "vrf context #{vrf} af #{af}: "\
             'v route-target both auto should be disabled')
    end

    if validate_property_excluded?('vrf_af', 'route_target_both_auto_evpn')
      assert_raises(Cisco::UnsupportedError) do
        v.route_target_both_auto_evpn = true
      end
    else
      v.route_target_both_auto_evpn = true
      assert(v.route_target_both_auto_evpn, "vrf context #{vrf} af #{af}: "\
             'v route-target both auto evpn should be enabled')

      v.route_target_both_auto_evpn = false
      refute(v.route_target_both_auto_evpn, "vrf context #{vrf} af #{af}: "\
             'v route-target both auto evpn should be disabled')
    end

    opts = [:import, :export]

    # Master list of communities to test against
    master = ['1:1', '2:2', '3:3', '4:5']

    # Test 1: both/import/export when no commands are present. Each target
    # option will be tested with and without evpn (6 separate types)
    should = master.clone
    route_target_tester(v, af, opts, should, 'Test 1')

    # Test 2: remove half of the entries
    should = ['1:1', '4:4']
    route_target_tester(v, af, opts, should, 'Test 2')

    # Test 3: restore the removed entries
    should = master.clone
    route_target_tester(v, af, opts, should, 'Test 3')

    # Test 4: 'default'
    should = v.default_route_target_import
    route_target_tester(v, af, opts, should, 'Test 4')
    v.destroy
  end

  def route_target_tester(v, af, opts, should, test_id)
    # First configure all four property types
    opts.each do |opt|
      # non-evpn
      v.send("route_target_#{opt}=", should)
      # evpn
      if validate_property_excluded?('vrf_af', "route_target_#{opt}_evpn")
        assert_raises(Cisco::UnsupportedError, "route_target_#{opt}_evpn=") do
          v.send("route_target_#{opt}_evpn=", should)
        end
      else
        v.send("route_target_#{opt}_evpn=", should)
      end
      # stitching
      if platform == :nexus
        assert_raises(Cisco::UnsupportedError,
                      "route_target_#{opt}_stitching=") do
          v.send("route_target_#{opt}_stitching=", should)
        end
      else
        v.send("route_target_#{opt}_stitching=", should)
      end
    end

    # Now check the results
    opts.each do |opt|
      # non-evpn
      result = v.send("route_target_#{opt}")
      assert_equal(should, result,
                   "#{test_id} : #{af} : route_target_#{opt}")
      # evpn
      result = v.send("route_target_#{opt}_evpn")
      if validate_property_excluded?('vrf_af', "route_target_#{opt}_evpn")
        assert_nil(result)
      else
        assert_equal(should, result,
                     "#{test_id} : #{af} : route_target_#{opt}_evpn")
      end
      # stitching
      result = v.send("route_target_#{opt}_stitching")
      if platform == :nexus
        assert_nil(result)
      else
        assert_equal(should, result,
                     "#{test_id} : #{af} : route_target_#{opt}_stitching")
      end
    end
  end
end
