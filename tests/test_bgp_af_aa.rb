# Copyright (c) 2017 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/bgp_af'
require_relative '../lib/cisco_node_utils/bgp_af_aggr_addr'

include Cisco
# TestBgpAfAggrAddr - Minitest for BgpAFAggrAddr class
class TestBgpAfAggrAddr < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    config('no feature bgp')
    remove_all_vrfs if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    config('no feature bgp')
    remove_all_vrfs
    super
  end

  def test_collection_empty
    node.cache_flush
    aas = RouterBgpAFAggrAddr.aas
    assert_empty(aas, 'BGP AF Aggregate Address collection is not empty')
  end

  def test_collection_not_empty
    bgp_af = []
    bgp_af_aa = []
    %w(default red).each do |vrf|
      [%w(ipv4 unicast), %w(ipv6 unicast),
       %w(ipv4 multicast), %w(ipv6 multicast)].each do |af|
        bgp_af.push(RouterBgpAF.new(55, vrf, af))
        if af[0] == 'ipv4'
          ['1.1.1.0/24', '2.2.2.2/32'].each do |addr|
            bgp_af_aa.push(RouterBgpAFAggrAddr.new(55, vrf, af, addr))
          end
        else
          ['2001::12/128', '2000::31/128'].each do |addr|
            bgp_af_aa.push(RouterBgpAFAggrAddr.new(55, vrf, af, addr))
          end
        end
        assert_equal(2, RouterBgpAFAggrAddr.aas[55][vrf][af].size)
      end
    end
  end

  def test_destroy
    af = %w(ipv4 unicast)
    RouterBgpAF.new(55, 'red', af)
    obj = RouterBgpAFAggrAddr.new(55, 'red', af, '1.1.1.0/24')
    aas = RouterBgpAFAggrAddr.aas[55]['red'][af]
    assert_equal(1, aas.size)
    obj.destroy
    aas = RouterBgpAFAggrAddr.aas[55]['red'][af]
    assert_empty(aas, 'BGP AF Aggregate Address collection is not empty')
  end

  def aa_helper(props)
    af = %w(ipv4 unicast)
    RouterBgpAF.new(55, 'red', af)
    obj = RouterBgpAFAggrAddr.new(55, 'red', af, '1.1.1.0/24')
    test_hash = {
      advertise_map: obj.default_advertise_map,
      as_set:        obj.default_as_set,
      attribute_map: obj.default_attribute_map,
      summary_only:  obj.default_summary_only,
      suppress_map:  obj.default_suppress_map,
    }.merge!(props)
    obj.aa_set(test_hash)
    obj
  end

  def test_aa
    obj = aa_helper(advertise_map: 'adm',
                    as_set:        true,
                    attribute_map: 'atm',
                    suppress_map:  'sum')
    assert(obj.as_set)
    assert_equal('adm', obj.advertise_map)
    assert_equal('atm', obj.attribute_map)
    assert_equal('sum', obj.suppress_map)
    obj = aa_helper(advertise_map: 'adm',
                    as_set:        true,
                    attribute_map: 'atm',
                    summary_only:  true)
    assert(obj.as_set)
    assert(obj.summary_only)
    assert_equal('adm', obj.advertise_map)
    assert_equal('atm', obj.attribute_map)
  end
end
