#!/usr/bin/env ruby
# RouterBgpNeighbor Unit Tests
#
# Jie Yang, August 2015
#
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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/bgp", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/bgp_neighbor", __FILE__)

class TestRouterBgpNeighbor < CiscoTestCase
  @@asn = 55
  @@addr = "1.1.1.1"

  def setup
    # Disable feature bgp before each test to ensure we
    # are starting with a clean slate for each test.
    super
    @device.cmd("configure terminal")
    @device.cmd("no feature bgp")
    @device.cmd("feature bgp")
    @device.cmd("router bgp 55")
    @device.cmd("end")
    node.cache_flush
  end

  def teardown
    @device.cmd("configure terminal")
    @device.cmd("no feature bgp")
    @device.cmd("end")
    node.cache_flush
  end

  def get_bgpneighbor_match_line(addr, vrf='default')
    if vrf == 'default'
      cmd = "show run bgp all | section 'router bgp' | no-more"
    else
      cmd = "show run bgp all | section 'vrf #{vrf}' | no-more"
    end
    CiscoLogger.debug("matching #{addr} with vrf #{vrf}")
    s = @device.cmd("#{cmd}")
    line = /neighbor #{addr}/.match(s)
    CiscoLogger.debug(line)
    line
  end

  def test_bgpneighbor_collection_empty
    @device.cmd("configure terminal")
    @device.cmd("no feature bgp")
    @device.cmd("end")
    node.cache_flush
    neighbors = RouterBgpNeighbor.neighbors
    assert_empty(neighbors, "BGP neighbor collection is not empty")
  end

  def test_bgpneighbor_collection_not_empty
    @device.cmd("configure terminal")
    @device.cmd("router bgp 55")
    @device.cmd("neighbor 1.1.1.1")
    @device.cmd("vrf red")
    @device.cmd("neighbor 2.2.2.0/24")
    @device.cmd("neighbor 2000::2")
    @device.cmd("neighbor 2000:123:38::/64")
    @device.cmd("end")
    node.cache_flush
    neighbors = RouterBgpNeighbor.neighbors
    refute_empty(neighbors, "BGP neighbor collection is empty")
    # validate the collection
    neighbors.each do |asnum, vrfs|
      vrfs.each do |vrf, neighbors|
          if vrf == 'default'
            assert_equal(1, neighbors.size)
          else
            assert_equal(3, neighbors.size)
          end
          neighbors.each {|addr, neighbor|
             assert_equal(vrf, neighbor.vrf)
             line = get_bgpneighbor_match_line(neighbor.address, vrf)
             refute_nil(line)
          }
      end
    end
  end

  def test_bgpneighbor_create_destroy
    address = { "1.1.1.1" => "1.1.1.1",
                "2.2.2.2/24" => "2.2.2.0/24",
                "2000::2" => "2000::2",
                "2000:123:38::34/64" => "2000:123:38::/64", }
    vrfs = %w(default red)
    vrfs.each {|vrf|
      address.each { |addr, expected_addr|
        neighbor = RouterBgpNeighbor.new(@@asn, vrf, addr)
        line = get_bgpneighbor_match_line(expected_addr, vrf)
        refute_nil(line, "Error: failed to create bgp neighbor #{addr}")
        neighbor.destroy
        line = get_bgpneighbor_match_line(expected_addr, vrf)
        assert_nil(line, "Error: failed to delete bgp neighbor #{addr}")
      }
    }
  end

  def test_bgpneighbor_set_get_description
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      description = "tested by mini test for vrf #{vrf}"
      neighbor.description = description
      assert_equal(description, neighbor.description)
      neighbor.description = " "
      assert(neighbor.description.empty?)
      neighbor.description = neighbor.default_description
      assert_equal(neighbor.description, neighbor.default_description)
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_multiple_descriptions
    # First create multiple routers with multiple desriptions.
    address = ["1.1.1.1", "2.2.2.0/24", "2000::2", "2000:123:38::/64"]
    vrfs = %w(default red)
    vrfs.each {|vrf|
      address.each { |addr|
        neighbor = RouterBgpNeighbor.new(@@asn, vrf, addr)
        neighbor.description = "#{vrf}:#{addr}"
      }
    }
    # Now test if the description has been correctly set
    RouterBgpNeighbor.neighbors.each do |asnum, vrfs|
      vrfs.each do |vrf, neighbors|
        neighbors.each {|addr, neighbor|
          assert_equal("#{vrf}:#{addr}", neighbor.description)
          neighbor.description = ""
          assert(neighbor.description.empty?)
          neighbor.description = neighbor.default_description
          assert_equal(neighbor.description, neighbor.default_description)
          neighbor.destroy
        }
      end
    end
  end

  def test_bgpneighbor_set_get_disable_connected_check
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_disable_connected_check]
      check.each { |value|
        neighbor.disable_connected_check = value
        assert_equal(value, neighbor.disable_connected_check)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_dont_capability_negotiate
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_dont_capability_negotiate]
      check.each { |value|
        neighbor.dont_capability_negotiate = value
        assert_equal(value, neighbor.dont_capability_negotiate)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_dynamic_capability
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_dynamic_capability]
      check.each { |value|
        neighbor.dynamic_capability = value
        assert_equal(value, neighbor.dynamic_capability)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_ebgp_multihop
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      ttls = [24, neighbor.default_ebgp_multihop]
      ttls.each { |ebgp_multihop|
        neighbor.ebgp_multihop = ebgp_multihop
        assert_equal(ebgp_multihop, neighbor.ebgp_multihop)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_local_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      local_asnum = [42, "1.1", neighbor.default_local_as]
      local_asnum.each { |asnum|
        neighbor.local_as = asnum
        assert_equal(asnum, neighbor.local_as)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_log_neighbor_changes
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [:true, :false, :default]
      check.each { |value|
        neighbor.log_neighbor_changes = value
        assert_equal(value, neighbor.log_neighbor_changes)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_low_memory_exempt
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_low_memory_exempt]
      check.each { |value|
        neighbor.low_memory_exempt = value
        assert_equal(value, neighbor.low_memory_exempt)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_maximum_peers
    # only "address/prefix" type of neighbor address will accept
    # maximum_peers command
    addr = "1.1.1.0/24"
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, addr)
      peers = [200, neighbor.default_maximum_peers]
      peers.each { |num|
        neighbor.maximum_peers = num
        assert_equal(num, neighbor.maximum_peers)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_password_and_type
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      passwords = { :cleartext => "test",
                    :"3des" => "386c0565965f89de",
                    :cisco_type_7 => "046E1803362E595C260E0B240619050A2D" }
      passwords.each { |type, password|
        neighbor.password_type = type
        neighbor.password = password
        if type == :cleartext
          assert_equal(:"3des", neighbor.password_type)
          assert_equal(passwords[:"3des"], neighbor.password)
        else
          assert_equal(type, neighbor.password_type)
          assert_equal(password, neighbor.password)
        end
        # now test removing the password setting
        neighbor.password = " "
        assert(neighbor.password.empty?)
        # now test default password
        neighbor.password = neighbor.default_password
        assert_equal(neighbor.default_password, neighbor.password)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_default_password_type
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      password = "test"
      expected_password = "386c0565965f89de"

      # Test 1: if we don't set password type, default should be cleartext,
      # we can verify by checking return type to be :3des, and encrypted text.
      neighbor.password = password
      assert_equal(expected_password, neighbor.password)
      assert_equal(:"3des", neighbor.password_type)
      # clear password
      neighbor.password = ""
      assert(neighbor.password.empty?)

      # Test 2: we set explicitly the password type to be default password type:
      # cleartext, and verify.
      neighbor.password_type = neighbor.default_password_type
      neighbor.password = password
      assert_equal(expected_password, neighbor.password)
      assert_equal(:"3des", neighbor.password_type)
      neighbor.password = ""
      assert(neighbor.password.empty?)
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_remote_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      remote_asnum = [42, "1.1", neighbor.default_remote_as]
      remote_asnum.each { |asnum|
        neighbor.remote_as = asnum
        assert_equal(asnum, neighbor.remote_as)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_remove_private_as_options
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      options = [:all, :"replace-as"]
      options.each { |option|
        neighbor.remove_private_as = option
        assert_equal(option, neighbor.remove_private_as)
      }

      neighbor.remove_private_as = neighbor.default_remove_private_as
      assert_equal(neighbor.default_remove_private_as,
                   neighbor.remove_private_as)
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_shutdown
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_shutdown]
      check.each { |value|
        neighbor.shutdown = value
        assert_equal(value, neighbor.shutdown)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_suppress_4_byte_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_suppress_4_byte_as]
      check.each { |value|
        neighbor.suppress_4_byte_as = value
        assert_equal(value, neighbor.suppress_4_byte_as)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_timers
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      timers = [{ :keep => 40, :hold => 90 },
                { :keep => neighbor.default_timers_keepalive,
                  :hold => neighbor.default_timers_holdtime },
                { :keep => neighbor.default_timers_keepalive,
                  :hold => 90 },
                { :keep => 40, :hold => neighbor.default_timers_holdtime },]
      timers.each { |timer|
        neighbor.timers_set(timer[:keep], timer[:hold])
        assert_equal(timer[:keep], neighbor.timers_keepalive)
        assert_equal(timer[:hold], neighbor.timers_holdtime)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_transport_passive_only
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_transport_passive_only]
      check.each { |value|
        neighbor.transport_passive_only = value
        assert_equal(value, neighbor.transport_passive_only)
      }
      neighbor.destroy
    end
  end

  def test_bgpneighbor_set_get_update_source
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      interfaces = ["loopback1", "Ethernet1/1", "ethernet1/1",
                    neighbor.default_update_source]
      interfaces.each { |interface|
        neighbor.update_source = interface
        assert_equal(interface.downcase, neighbor.update_source)
      }
      neighbor.destroy
    end
  end
end
