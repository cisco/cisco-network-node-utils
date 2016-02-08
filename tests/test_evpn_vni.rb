# Evpn Vni Unit Tests
#
# Andi Shen, December, 2015
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
require_relative '../lib/cisco_node_utils/evpn_vni'

# TestEvpnVni - Minitest for EvpnVni class
class TestEvpnVni < CiscoTestCase
  def setup
    # Disable feature bgp and no overlay evpn before each test to
    # ensure we are starting with a clean slate for each test.
    super
    config('no feature bgp')
    config('no nv overlay evpn')
    config('no evpn')
  end

  def test_create_and_destroy
    vni = EvpnVni.new(4096)
    vni_list = EvpnVni.vnis
    assert(vni_list.key?('4096'), 'Error: failed to create evpn vni 4096')

    vni.destroy
    vni_list = EvpnVni.vnis
    refute(vni_list.key?('4096'), 'Error: failed to destroy evpn vni 4096')
  end

  def test_vni_collection
    vni_list = EvpnVni.vnis
    assert_equal(true, vni_list.empty?, 'VLAN collection is empty')
  end

  def test_route_distinguisher
    vni = EvpnVni.new(4096)
    vni.route_distinguisher = 'auto'
    assert_equal('auto', vni.route_distinguisher,
                 "vni route_distinguisher should be set to 'auto'")
    vni.route_distinguisher = '1:1'
    assert_equal('1:1', vni.route_distinguisher,
                 "vni route_distinguisher should be set to '1:1'")
    vni.route_distinguisher = vni.default_route_distinguisher
    assert_empty(vni.route_distinguisher,
                 'vni route_distinguisher should *NOT* be configured')
    vni.destroy
  end

  # test route_target
  def test_route_target
    vni = EvpnVni.new(4096)

    # test route target both auto and route target both auto evpn
    opts = [:both, :import, :export]

    # Master list of communities to test against
    master = ['1.2.3.4:55', '2:2', '55:33', 'auto']

    # Test 1: both/import/export when no commands are present. Each target
    should = master.clone
    route_target_tester(vni, opts, should, 'Test 1')

    # Test 2: remove half of the entries
    should = ['2:2', 'auto']
    route_target_tester(vni, opts, should, 'Test 2')

    # Test 3: restore the removed entries
    should = master.clone
    route_target_tester(vni, opts, should, 'Test 3')

    # Test 4: 'default'
    should = vni.default_route_target_import
    route_target_tester(vni, opts, should, 'Test 4')

    vni .destroy
  end

  def route_target_tester(vni, opts, should, test_id)
    # First configure all four property types
    opts.each do |opt|
      # non-evpn
      vni.send("route_target_#{opt}=", should)
    end

    # Now check the results
    opts.each do |opt|
      # non-evpn
      result = vni.send("route_target_#{opt}")
      assert_equal(should, result,
                   "#{test_id} : route_target_#{opt}")
    end
  end
end
