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
require_relative '../lib/cisco_node_utils/vrf'
require_relative '../lib/cisco_node_utils/vrf_af'
require_relative '../lib/cisco_node_utils/vni'

include Cisco

# TestVrf - Minitest for Vrf node utility class
class TestVrf < CiscoTestCase
  VRF_NAME_SIZE = 33

  def setup
    super
    vrf_clean
  end

  def teardown
    super
    vrf_clean
  end

  def vrf_clean
    vrfs = Vrf.vrfs
    vrfs.keys do |vrf|
      next if vrf[/management/]
      config("no vrf context #{vrf}")
    end
  end

  def test_collection_not_empty
    vrfs = Vrf.vrfs
    refute_empty(vrfs, 'VRF collection is empty')
    assert(vrfs.key?('management'), 'VRF management does not exist')
  end

  def test_create_and_destroy
    v = Vrf.new('test_vrf')
    vrfs = Vrf.vrfs
    assert(vrfs.key?('test_vrf'), 'Error: failed to create vrf test_vrf')

    v.destroy
    vrfs = Vrf.vrfs
    refute(vrfs.key?('test_vrf'), 'Error: failed to destroy vrf test_vrf')
  end

  def test_name_type_invalid
    assert_raises(TypeError, 'Wrong vrf name type did not raise type error') do
      Vrf.new(1000)
    end
  end

  def test_name_zero_length
    assert_raises(Cisco::CliError, "Zero length name didn't raise CliError") do
      Vrf.new('')
    end
  end

  def test_name_too_long
    name = 'a' * VRF_NAME_SIZE
    assert_raises(Cisco::CliError,
                  'vrf name misconfig did not raise CliError') do
      Vrf.new(name)
    end
  end

  def test_shutdown_valid
    shutdown_states = [true, false]
    v = Vrf.new('test_shutdown')
    shutdown_states.each do |start|
      shutdown_states.each do |finish|
        v.shutdown = start
        assert_equal(start, v.shutdown, 'start')
        v.shutdown = finish
        assert_equal(finish, v.shutdown, 'finish')
      end
    end
    v.destroy
  end

  def test_description
    vrf = Vrf.new('test_description')
    vrf.description = 'tested by minitest'
    assert_equal('tested by minitest', vrf.description,
                 'failed to set description')
    vrf.description = ' '
    assert_empty(vrf.description, 'failed to remove description')
    vrf.destroy
  end

  def test_vni
    skip('Platform does not support MT-lite') unless Vni.mt_lite_support
    vrf = Vrf.new('test_vni')
    vrf.vni = 4096
    assert_equal(4096, vrf.vni,
                 "vrf vni should be set to '4096'")
    vrf.vni = vrf.default_vni
    assert_equal(vrf.default_vni, vrf.vni,
                 'vrf vni should be set to default value')
    vrf.destroy
  end

  def test_route_distinguisher
    if node.product_id[/N3/]
      skip('Platform does not support nv overlay feature') unless
        Feature.nv_overlay_supported?
    end
    v = Vrf.new('blue')
    v.route_distinguisher = 'auto'
    assert_equal('auto', v.route_distinguisher)

    v.route_distinguisher = '1:1'
    assert_equal('1:1', v.route_distinguisher)

    v.route_distinguisher = '2:3'
    assert_equal('2:3', v.route_distinguisher)

    v.route_distinguisher = v.default_route_distinguisher
    assert_empty(v.route_distinguisher,
                 'v route_distinguisher should *NOT* be configured')
    v.destroy
  end

  def test_vrf_af_create_destroy
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

  def test_route_target
    [%w(ipv4 unicast), %w(ipv6 unicast)].each { |af| route_target(af) }
  end

  def route_target(af)
    # Common tester for route-target properties. Tests evpn and non-evpn.
    #   route_target_both_auto
    #   route_target_both_auto_evpn
    #   route_target_export
    #   route_target_export_evpn
    #   route_target_import
    #   route_target_import_evpn
    vrf = 'red'
    v = VrfAF.new(vrf, af)

    # test route target both auto and route target both auto evpn
    refute(v.default_route_target_both_auto,
           'default value for route target both auto should be false')

    refute(v.default_route_target_both_auto_evpn,
           'default value for route target both auto evpn should be false')

    v.route_target_both_auto = true
    assert(v.route_target_both_auto, "vrf context #{vrf} af #{af}: "\
           'v route-target both auto should be enabled')

    v.route_target_both_auto = false
    refute(v.route_target_both_auto, "vrf context #{vrf} af #{af}: "\
           'v route-target both auto should be disabled')

    v.route_target_both_auto_evpn = true
    assert(v.route_target_both_auto_evpn, "vrf context #{vrf} af #{af}: "\
           'v route-target both auto evpn should be enabled')

    v.route_target_both_auto_evpn = false
    refute(v.route_target_both_auto_evpn, "vrf context #{vrf} af #{af}: "\
           'v route-target both auto evpn should be disabled')

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
  end

  def route_target_tester(v, af, opts, should, test_id)
    # First configure all four property types
    opts.each do |opt|
      # non-evpn
      v.send("route_target_#{opt}=", should)
      # evpn
      v.send("route_target_#{opt}_evpn=", should)
    end

    # Now check the results
    opts.each do |opt|
      # non-evpn
      result = v.send("route_target_#{opt}")
      assert_equal(should, result,
                   "#{test_id} : #{af} : route_target_#{opt}")
      # evpn
      result = v.send("route_target_#{opt}_evpn")
      assert_equal(should, result,
                   "#{test_id} : #{af} : route_target_#{opt}_evpn")
    end
  end
end
