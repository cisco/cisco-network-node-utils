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
    # remove_all_ospfs
    super
  end

  def create_routerospfarea_default(router='Wolfpack', name='default',
                                    area_id='1.1.1.1')
    RouterOspfArea.new(router, name, area_id)
  end

  def create_routerospfarea_vrf(router='Wolfpack', name='blue',
                                area_id='1.1.1.1')
    RouterOspfArea.new(router, name, area_id)
  end

  def test_authentication
    ad = create_routerospfarea_default
    assert_equal(ad.default_authentication, ad.authentication)
    ad.authentication = 'md5'
    assert_equal('md5', ad.authentication)
    ad.authentication = 'clear_text'
    assert_equal('clear_text', ad.authentication)
    ad.authentication = ad.default_authentication
    assert_equal(ad.default_authentication, ad.authentication)
    av = create_routerospfarea_vrf
    assert_equal(av.default_authentication, av.authentication)
    av.authentication = 'md5'
    assert_equal('md5', av.authentication)
    av.authentication = 'clear_text'
    assert_equal('clear_text', av.authentication)
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
    ad.stub = 'no_summary'
    assert_equal('no_summary', ad.stub)
    ad.stub = 'summary'
    assert_equal('summary', ad.stub)
    ad.stub = ad.default_stub
    assert_equal(ad.default_stub, ad.stub)
    av = create_routerospfarea_vrf
    assert_equal(av.default_stub, av.stub)
    av.stub = 'no_summary'
    assert_equal('no_summary', av.stub)
    av.stub = 'summary'
    assert_equal('summary', av.stub)
    av.stub = av.default_stub
    assert_equal(av.default_stub, av.stub)
  end

  def test_range
    ad = create_routerospfarea_default
    assert_equal(ad.default_range, ad.range)
    ranges = [['10.3.0.0/16', true, '23'], ['10.3.0.0/32', true, false],
              ['10.3.0.1/32', false, false], ['10.3.3.0/24', false, 450]]
    ad.range = ranges
    assert_equal(ranges, ad.range)
    ad.range = ad.default_range
    assert_equal(ad.default_range, ad.range)
  end
end
