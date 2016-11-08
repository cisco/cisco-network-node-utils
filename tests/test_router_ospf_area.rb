# Copyright (c) 2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/router_ospf_area'

# TestRouterOspfArea - Minitest for RouterOspfArea node utility class
class TestRouterOspfArea < CiscoTestCase
  @skip_unless_supported = 'ospf_area'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_ospfs if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    remove_all_ospfs
    config 'no feature ospf'
    super
  end

  def create_routerospfarea_default(router='Wolfpack', name='default',
                                    area_id='1.1.1.1')
    RouterOspfArea.new(router, name, area_id)
  end

  def create_routerospfarea_vrf(router='Wolfpack', name='blue',
                                area_id='1450')
    RouterOspfArea.new(router, name, area_id)
  end

  def test_collection_size
    ad = create_routerospfarea_default
    ad.stub = true
    assert_equal(1, RouterOspfArea.areas['Wolfpack'].size)
    av = create_routerospfarea_vrf
    av.stub = true
    assert_equal(2, RouterOspfArea.areas['Wolfpack'].size)
    av.destroy
    # on n9k-f (only), we cannot remove "area <area> default-cost 1",
    # unless the entire ospf router is removed. The default value of
    # default_cost is 1 and so this is just a cosmetic issue but
    # need to skip the below test as the size will be wrong.
    # platform as the size will be wrong. bug ID: CSCva04066
    assert_equal(1, RouterOspfArea.areas['Wolfpack'].size) unless
      /N9K.*-F/ =~ node.product_id
    ad.destroy
    assert_empty(RouterOspfArea.areas) unless
      /N9K.*-F/ =~ node.product_id
  end

  def test_authentication
    ad = create_routerospfarea_default
    assert_equal(ad.default_authentication, ad.authentication)
    ad.authentication = 'md5'
    assert_equal('md5', ad.authentication)
    ad.authentication = 'cleartext'
    assert_equal('cleartext', ad.authentication)
    ad.authentication = ad.default_authentication
    assert_equal(ad.default_authentication, ad.authentication)
    av = create_routerospfarea_vrf
    assert_equal(av.default_authentication, av.authentication)
    av.authentication = 'md5'
    assert_equal('md5', av.authentication)
    av.authentication = 'cleartext'
    assert_equal('cleartext', av.authentication)
    av.authentication = av.default_authentication
    assert_equal(av.default_authentication, av.authentication)
  end

  def test_default_cost
    ad = create_routerospfarea_default
    assert_equal(ad.default_default_cost, ad.default_cost)
    ad.default_cost = 2000
    assert_equal(2000, ad.default_cost)
    ad.default_cost = ad.default_default_cost
    assert_equal(ad.default_default_cost, ad.default_cost)
    av = create_routerospfarea_vrf
    assert_equal(av.default_default_cost, av.default_cost)
    av.default_cost = 10_000
    assert_equal(10_000, av.default_cost)
    av.default_cost = av.default_default_cost
    assert_equal(av.default_default_cost, av.default_cost)
  end

  def test_filter_list
    ad = create_routerospfarea_default
    assert_equal(ad.default_filter_list_in, ad.filter_list_in)
    assert_equal(ad.default_filter_list_out, ad.filter_list_out)
    ad.filter_list_in = 'abc'
    assert_equal('abc', ad.filter_list_in)
    ad.filter_list_out = 'efg'
    assert_equal('efg', ad.filter_list_out)
    ad.filter_list_in = ad.default_filter_list_in
    assert_equal(ad.default_filter_list_in, ad.filter_list_in)
    ad.filter_list_out = ad.default_filter_list_out
    assert_equal(ad.default_filter_list_out, ad.filter_list_out)
    av = create_routerospfarea_vrf
    assert_equal(av.default_filter_list_in, av.filter_list_in)
    assert_equal(av.default_filter_list_out, av.filter_list_out)
    av.filter_list_in = 'uvw'
    assert_equal('uvw', av.filter_list_in)
    av.filter_list_out = 'xyz'
    assert_equal('xyz', av.filter_list_out)
    av.filter_list_in = av.default_filter_list_in
    assert_equal(av.default_filter_list_in, av.filter_list_in)
    av.filter_list_out = av.default_filter_list_out
    assert_equal(av.default_filter_list_out, av.filter_list_out)
  end

  def test_stub
    ad = create_routerospfarea_default
    assert_equal(ad.default_stub, ad.stub)
    assert_equal(ad.default_stub_no_summary, ad.stub_no_summary)
    ad.stub = true
    assert_equal(true, ad.stub)
    assert_equal(ad.default_stub_no_summary, ad.stub_no_summary)
    ad.stub_no_summary = true
    assert_equal(true, ad.stub_no_summary)
    assert_equal(true, ad.stub)
    ad.stub_no_summary = ad.default_stub_no_summary
    assert_equal(ad.default_stub_no_summary, ad.stub_no_summary)
    assert_equal(true, ad.stub)
    ad.stub = ad.default_stub
    assert_equal(ad.default_stub, ad.stub)
    assert_equal(ad.default_stub_no_summary, ad.stub_no_summary)
    av = create_routerospfarea_vrf
    assert_equal(av.default_stub, av.stub)
    assert_equal(av.default_stub_no_summary, av.stub_no_summary)
    av.stub = true
    assert_equal(true, av.stub)
    assert_equal(av.default_stub_no_summary, av.stub_no_summary)
    av.stub_no_summary = true
    assert_equal(true, av.stub_no_summary)
    assert_equal(true, av.stub)
    av.stub_no_summary = av.default_stub_no_summary
    assert_equal(av.default_stub_no_summary, av.stub_no_summary)
    assert_equal(true, av.stub)
    av.stub = av.default_stub
    assert_equal(av.default_stub, av.stub)
    assert_equal(av.default_stub_no_summary, av.stub_no_summary)
  end

  def test_range
    ad = create_routerospfarea_default
    assert_equal(ad.default_range, ad.range)
    ranges = [['10.3.0.0/16', 'not_advertise', '23'],
              ['10.3.0.0/32', 'not_advertise'],
              ['10.3.0.1/32'],
              ['10.3.3.0/24', '450']]
    ad.range = ranges
    assert_equal(ranges, ad.range)
    ranges = [['10.3.0.0/16', 'not_advertise', '23'],
              ['10.3.3.0/24', '450']]
    ad.range = ranges
    assert_equal(ranges, ad.range)
    ad.range = ad.default_range
    assert_equal(ad.default_range, ad.range)
    av = create_routerospfarea_vrf
    assert_equal(av.default_range, av.range)
    ranges = [['10.3.0.0/16', '8000'],
              ['10.3.0.0/32', 'not_advertise'],
              ['10.3.0.1/32'],
              ['10.3.3.0/24', 'not_advertise', '10212']]
    av.range = ranges
    assert_equal(ranges, av.range)
    ranges = [['10.3.0.0/16', '4989'],
              ['10.3.1.1/32'],
              ['10.3.3.0/24', 'not_advertise', '76376']]
    av.range = ranges
    assert_equal(ranges, av.range)
    av.range = av.default_range
    assert_equal(av.default_range, av.range)
  end

  def test_nssa
    hash = {}
    ad = create_routerospfarea_default
    assert_equal(ad.default_nssa, ad.nssa)
    hash[:nssa] = true
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(ad.default_nssa_default_originate, ad.nssa_default_originate)
    assert_equal(ad.default_nssa_no_redistribution, ad.nssa_no_redistribution)
    assert_equal(ad.default_nssa_no_summary, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)

    hash = {}
    ad.nssa_set(hash)
    assert_equal(ad.default_nssa, ad.nssa)
    assert_equal(ad.default_nssa_default_originate, ad.nssa_default_originate)
    assert_equal(ad.default_nssa_no_redistribution, ad.nssa_no_redistribution)
    assert_equal(ad.default_nssa_no_summary, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)

    av = create_routerospfarea_vrf
    assert_equal(av.default_nssa, av.nssa)
    hash[:nssa] = true
    av.nssa_set(hash)
    assert_equal(true, av.nssa)
    assert_equal(av.default_nssa_default_originate, av.nssa_default_originate)
    assert_equal(av.default_nssa_no_redistribution, av.nssa_no_redistribution)
    assert_equal(av.default_nssa_no_summary, av.nssa_no_summary)
    assert_equal(av.default_nssa_route_map, av.nssa_route_map)

    hash = {}
    av.nssa_set(hash)
    assert_equal(av.default_nssa, av.nssa)
    assert_equal(av.default_nssa_default_originate, av.nssa_default_originate)
    assert_equal(av.default_nssa_no_redistribution, av.nssa_no_redistribution)
    assert_equal(av.default_nssa_no_summary, av.nssa_no_summary)
    assert_equal(av.default_nssa_route_map, av.nssa_route_map)
  end

  def nssa_helper(ad)
    hash = {}
    hash[:nssa] = true
    hash[:nssa_default_originate] = true
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert(ad.nssa_default_originate)
    assert_equal(ad.default_nssa_no_redistribution, ad.nssa_no_redistribution)
    assert_equal(ad.default_nssa_no_summary, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)
    # on n9k-f (only), we cannot configure
    # "area <area> nssa default-information-originate",
    # properly if we reset it first. It is only configuring nssa
    # but not the other parameters. bug ID: CSCva11482
    hash[:nssa_route_map] = 'aaa'
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    if node.product_id[/N9K-F/]
      refute(ad.nssa_default_originate)
    else
      assert(ad.nssa_default_originate)
    end
    assert_equal(ad.default_nssa_no_redistribution, ad.nssa_no_redistribution)
    assert_equal(ad.default_nssa_no_summary, ad.nssa_no_summary)
    if node.product_id[/N9K-F/]
      refute_equal('aaa', ad.nssa_route_map)
    else
      assert_equal('aaa', ad.nssa_route_map)
    end
    hash[:nssa_no_summary] = true
    hash.delete(:nssa_route_map)
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(true, ad.nssa_default_originate)
    assert_equal(ad.default_nssa_no_redistribution, ad.nssa_no_redistribution)
    assert_equal(true, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)
    hash[:nssa_route_map] = 'aaa'
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(true, ad.nssa_default_originate)
    assert_equal(ad.default_nssa_no_redistribution, ad.nssa_no_redistribution)
    assert_equal(true, ad.nssa_no_summary)
    assert_equal('aaa', ad.nssa_route_map)

    hash = {}
    hash[:nssa] = true
    hash[:nssa_default_originate] = true
    hash[:nssa_no_redistribution] = true
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(true, ad.nssa_default_originate)
    assert_equal(true, ad.nssa_no_redistribution)
    assert_equal(ad.default_nssa_no_summary, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)
    hash = {}
    hash[:nssa] = true
    hash[:nssa_default_originate] = true
    hash[:nssa_no_redistribution] = true
    hash[:nssa_route_map] = 'aaa'
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(true, ad.nssa_default_originate)
    assert_equal(true, ad.nssa_no_redistribution)
    assert_equal(ad.default_nssa_no_summary, ad.nssa_no_summary)
    assert_equal('aaa', ad.nssa_route_map)
    hash = {}
    hash[:nssa] = true
    hash[:nssa_default_originate] = true
    hash[:nssa_no_redistribution] = true
    hash[:nssa_route_map] = 'aaa'
    hash[:nssa_no_summary] = true
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(true, ad.nssa_default_originate)
    assert_equal(true, ad.nssa_no_redistribution)
    assert_equal(true, ad.nssa_no_summary)
    assert_equal('aaa', ad.nssa_route_map)
    hash = {}
    hash[:nssa] = true
    hash[:nssa_no_redistribution] = true
    hash[:nssa_no_summary] = true
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(ad.default_nssa_default_originate, ad.nssa_default_originate)
    assert_equal(true, ad.nssa_no_redistribution)
    assert_equal(true, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)
    hash = {}
    hash[:nssa] = true
    hash[:nssa_no_redistribution] = true
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(ad.default_nssa_default_originate, ad.nssa_default_originate)
    assert_equal(true, ad.nssa_no_redistribution)
    assert_equal(ad.default_nssa_no_summary, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)
    hash = {}
    hash[:nssa] = true
    hash[:nssa_no_summary] = true
    ad.nssa_set(hash)
    assert_equal(true, ad.nssa)
    assert_equal(ad.default_nssa_default_originate, ad.nssa_default_originate)
    assert_equal(ad.default_nssa_no_redistribution, ad.nssa_no_redistribution)
    assert_equal(true, ad.nssa_no_summary)
    assert_equal(ad.default_nssa_route_map, ad.nssa_route_map)
  end

  def test_nssa_non_default_vrf_others
    nssa_helper(create_routerospfarea_vrf)
  end

  def test_nssa_default_vrf_others
    nssa_helper(create_routerospfarea_default)
  end

  def test_nssa_translate_type7
    ad = create_routerospfarea_default
    assert_equal(ad.default_nssa_translate_type7, ad.nssa_translate_type7)
    ad.nssa_translate_type7 = 'never'
    assert_equal('never', ad.nssa_translate_type7)
    ad.nssa_translate_type7 = 'supress_fa'
    assert_equal('supress_fa', ad.nssa_translate_type7)
    ad.nssa_translate_type7 = 'always_supress_fa'
    assert_equal('always_supress_fa', ad.nssa_translate_type7)
    ad.nssa_translate_type7 = 'always'
    assert_equal('always', ad.nssa_translate_type7)
    ad.nssa_translate_type7 = ad.default_nssa_translate_type7
    assert_equal(ad.default_nssa_translate_type7, ad.nssa_translate_type7)
    av = create_routerospfarea_vrf
    assert_equal(av.default_nssa_translate_type7, av.nssa_translate_type7)
    av.nssa_translate_type7 = 'never'
    assert_equal('never', av.nssa_translate_type7)
    av.nssa_translate_type7 = 'supress_fa'
    assert_equal('supress_fa', av.nssa_translate_type7)
    av.nssa_translate_type7 = 'always_supress_fa'
    assert_equal('always_supress_fa', av.nssa_translate_type7)
    av.nssa_translate_type7 = 'always'
    assert_equal('always', av.nssa_translate_type7)
    av.nssa_translate_type7 = av.default_nssa_translate_type7
    assert_equal(av.default_nssa_translate_type7, av.nssa_translate_type7)
  end

  def test_destroy
    ad = create_routerospfarea_default
    # destroy without changing any properties
    ad.destroy
    [:authentication,
     :default_cost,
     :filter_list_in,
     :filter_list_out,
     :range,
     :nssa,
     :nssa_default_originate,
     :nssa_no_redistribution,
     :nssa_no_summary,
     :nssa_route_map,
     :nssa_translate_type7,
     :stub,
     :stub_no_summary,
    ].each do |prop|
      assert_equal(ad.send("default_#{prop}"), ad.send("#{prop}"))
    end
    ad.authentication = 'md5'
    ad.default_cost = 2000
    ad.filter_list_in = 'abc'
    ad.filter_list_out = 'efg'
    ranges = [['10.3.0.0/16', 'not_advertise', '23'],
              ['10.3.0.0/32', 'not_advertise'],
              ['10.3.0.1/32'],
              ['10.3.3.0/24', '450']]
    hash = {}
    hash[:nssa] = true
    hash[:default_information_originate] = 'default-information-originate'
    hash[:no_summary] = 'no-summary'
    hash[:no_redistribution] = 'no-redistribution'
    hash[:route_map] = 'route-map'
    hash[:rm] = 'aaa'
    ad.nssa_set(hash)

    ad.nssa_translate_type7 = 'never'
    ad.range = ranges
    ad.stub = true
    ad.stub_no_summary = true
    # destroy after changing properties
    ad.destroy
    [:authentication,
     :default_cost,
     :filter_list_in,
     :filter_list_out,
     :range,
     :nssa,
     :nssa_default_originate,
     :nssa_no_redistribution,
     :nssa_no_summary,
     :nssa_route_map,
     :nssa_translate_type7,
     :stub,
     :stub_no_summary,
    ].each do |prop|
      assert_equal(ad.send("default_#{prop}"), ad.send("#{prop}"))
    end
  end
end
