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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/router_ospf", __FILE__)

class TestRouterOspf < CiscoTestCase
  def routerospf_routers_destroy(routers)
    routers.each { |name, router| router.destroy }
  end

  def get_routerospf_match_line(name)
    s = @device.cmd("show run | include '^router ospf .*'")
    cmd = "router ospf"
    line = /#{cmd}\s#{name}/.match(s)
  end

  def test_routerospf_collection_empty
    s = @device.cmd("configure terminal")
    s = @device.cmd("no feature ospf")
    s = @device.cmd("end")
    node.cache_flush
    routers = RouterOspf.routers
    assert_equal(true, routers.empty?(),
                   "RouterOspf collection is not empty")
  end

  def test_routerospf_collection_not_empty
    s = @device.cmd("configure terminal")
    s = @device.cmd("feature ospf")
    s = @device.cmd("router ospf TestOSPF")
    s = @device.cmd("router ospf 100")
    s = @device.cmd("end")
    node.cache_flush
    routers = RouterOspf.routers
    assert_equal(false, routers.empty?(),
                 "RouterOspf collection is empty")
    # validate the collection
    routers.each do |name, router|
      line = get_routerospf_match_line(name)
      assert_equal(false, line.nil?)
    end
    routerospf_routers_destroy(routers)
    routers=nil
  end

  def test_routerospf_create_name_zero_length
    assert_raises(ArgumentError) do
      ospf = RouterOspf.new("")
    end
  end

  def test_routerospf_create_valid
    name = "ospfTest"
    ospf = RouterOspf.new(name)
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    assert_equal(false, line.nil?,
                 "Error: 'router ospf ospfTest' not configured")
    ospf.destroy
  end

  def test_routerospf_create_valid_no_feature
    name = "ospfTest"
    ospf = RouterOspf.new(name)
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    assert_equal(false, line.nil?,
                 "Error: 'router ospf ospfTest' not configured")
    ospf.destroy

    s = @device.cmd("show run all | no-more")
    cmd = "feature ospf"
    line = /#{cmd}/.match(s)
    assert_equal(true, line.nil?,
                 "Error: 'feature ospf' still configured")
  end

  def test_routerospf_create_valid_multiple
    name = "ospfTest_1"
    ospf_1 = RouterOspf.new(name)
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    assert_equal(false, line.nil?,
                 "Error: 'router ospf ospfTest_1' not configured")

    name = "ospfTest_2"
    ospf_2 = RouterOspf.new(name)
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    assert_equal(false, line.nil?,
                 "Error: 'router ospf ospfTest_1' not configured")

    ospf_1.destroy
    ospf_2.destroy
  end

  def test_routerospf_get_name
    name = "ospfTest"
    ospf = RouterOspf.new(name)
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    name =  line.to_s.split(" ").last
    # puts "name from cli: #{name}"
    # puts "name from get: #{routerospf.name}"
    assert_equal(name, ospf.name,
                 "Error: router name not correct")
    ospf.destroy
  end

  def test_routerospf_destroy
    name = "ospfTest"
    ospf = RouterOspf.new(name)
    ospf.destroy
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    assert_equal(true, line.nil?,
                 "Error: 'router ospf ospfTest' not destroyed")
  end

  def test_routerospf_create_valid_multiple_delete_one
    name = "ospfTest_1"
    ospf_1 = RouterOspf.new(name)
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    assert_equal(false, line.nil?,
                 "Error: #{name}, not configured")

    name = "ospfTest_2"
    ospf_2 = RouterOspf.new(name)
    line = get_routerospf_match_line(name)
    # puts "cfg line: #{line}"
    assert_equal(false, line.nil?,
                 "Error: #{name}, not configured")

    ospf_1.destroy

    # Remove one router then check that we only have one router left
    routers = RouterOspf.routers
    assert_equal(false, routers.empty?(),
                 "Error: RouterOspf collection is empty")
    assert_equal(1, routers.size(),
                 "Error: RouterOspf collection is not one")
    assert_equal(true, routers.key?(name),
                 "Error: #{name}, not found in the collection")
    # validate the collection
    line = get_routerospf_match_line(name)
    assert_equal(false, line.nil?,
                 "Error: #{name}, instance not found")
    ospf_2.destroy
    routers = nil
  end
end
