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

# TestRouterOspf - Minitest for the RouterOspf node utility class.
class TestRouterOspf < CiscoTestCase
  @skip_unless_supported = 'ospf'

  def setup
    super
    remove_all_ospfs
  end

  def test_create_destroy
    assert_empty(RouterOspf.routers, 'RouterOspf.routers should be empty')

    # Create two ospf instances
    o1_name = 'ospf1'
    o1 = RouterOspf.new(o1_name)
    assert(RouterOspf.routers[o1_name],
           "router ospf #{o1_name} not present")
    assert_equal(o1_name, o1.name)

    o2_name = 'ospf2'
    o2 = RouterOspf.new(o2_name)
    assert(RouterOspf.routers[o2_name],
           "router ospf #{o2_name} not present")

    # Destroy each in turn
    o1.destroy
    assert_nil(RouterOspf.routers[o1_name],
               "router ospf #{o1_name} still present")
    assert(RouterOspf.routers[o2_name],
           "router ospf #{o2_name} not present")

    o2.destroy
    assert_nil(RouterOspf.routers[o2_name],
               "router ospf #{o2_name} still present")

    # Negative
    assert_raises(ArgumentError) { RouterOspf.new('') }
  end
end
