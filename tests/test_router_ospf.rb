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
  def setup
    super
    @default_show_command = "show run | include '^router ospf .*'"
  end

  def routerospf_routers_destroy(routers)
    routers.each_value(&:destroy)
  end

  def test_routerospf_collection_empty
    config('no feature ospf')
    routers = RouterOspf.routers
    assert_equal(true, routers.empty?,
                 'RouterOspf collection is not empty')
  end

  def test_routerospf_collection_not_empty
    config('feature ospf', 'router ospf TestOSPF', 'router ospf 100')
    routers = RouterOspf.routers
    assert_equal(false, routers.empty?,
                 'RouterOspf collection is empty')
    # validate the collection
    routers.each_key do |name|
      assert_show_match(pattern: /router ospf #{name}/)
    end
    routerospf_routers_destroy(routers)
  end

  def test_routerospf_create_name_zero_length
    assert_raises(ArgumentError) do
      RouterOspf.new('')
    end
  end

  def test_routerospf_create_valid
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "'router ospf ospfTest' not configured")
    ospf.destroy
  end

  def test_routerospf_create_valid_no_feature
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "'router ospf ospfTest' not configured")
    ospf.destroy

    refute_show_match(command: 'show run all | inc feature | no-more',
                      pattern: /feature ospf/,
                      msg:     "Error: 'feature ospf' still configured")
  end

  def test_routerospf_create_valid_multiple
    name = 'ospfTest_1'
    ospf_1 = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/)

    name = 'ospfTest_2'
    ospf_2 = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/)

    ospf_1.destroy
    ospf_2.destroy
  end

  def test_routerospf_get_name
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    line = assert_show_match(pattern: /router ospf #{name}/)
    name = line.to_s.split(' ').last
    # puts "name from cli: #{name}"
    # puts "name from get: #{routerospf.name}"
    assert_equal(name, ospf.name,
                 'Error: router name not correct')
    ospf.destroy
  end

  def test_routerospf_destroy
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    ospf.destroy
    refute_show_match(pattern: /router ospf #{name}/,
                      msg:     "'router ospf ospfTest' not destroyed")
  end

  def test_routerospf_create_valid_multiple_delete_one
    name = 'ospfTest_1'
    ospf_1 = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "Error: #{name}, not configured")

    name = 'ospfTest_2'
    ospf_2 = RouterOspf.new(name)
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "Error: #{name}, not configured")

    ospf_1.destroy

    # Remove one router then check that we only have one router left
    routers = RouterOspf.routers
    assert_equal(false, routers.empty?,
                 'Error: RouterOspf collection is empty')
    assert_equal(1, routers.size,
                 'Error: RouterOspf collection is not one')
    assert_equal(true, routers.key?(name),
                 "Error: #{name}, not found in the collection")
    # validate the collection
    assert_show_match(pattern: /router ospf #{name}/,
                      msg:     "Error: #{name}, instance not found")
    ospf_2.destroy
  end
end
