#!/usr/bin/env ruby
# RouterBgpNeighbor Unit Tests
#
# Jie Yang, August 2015
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
require_relative '../lib/cisco_node_utils/bgp'
require_relative '../lib/cisco_node_utils/bgp_neighbor'

# TestBgpNeighbor - Minitest for RouterBgpNeighbor node utility class
class TestBgpNeighbor < CiscoTestCase
  # rubocop:disable Style/ClassVars
  @@asn = 55
  @@addr = '1.1.1.1'
  @@pre_clean_needed = true
  # rubocop:enable Style/ClassVars

  def setup
    super
    remove_all_bgps if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
    # BGP Neighbor requires the presence of a basic bgp global config
    RouterBgp.new(@@asn)
  end

  def teardown
    super
    remove_all_bgps
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

  def test_collection_empty
    config('no feature bgp')
    neighbors = RouterBgpNeighbor.neighbors
    assert_empty(neighbors, 'BGP neighbor collection is not empty')
  end

  def test_collection_not_empty
    config('router bgp 55',
           'neighbor 1.1.1.1',
           'vrf red',
           'neighbor 2.2.2.0/24',
           'neighbor 2000::2',
           'neighbor 2000:123:38::/64')
    bgp_neighbors = RouterBgpNeighbor.neighbors
    refute_empty(bgp_neighbors, 'BGP neighbor collection is empty')
    # validate the collection
    bgp_neighbors.each_value do |vrfs|
      vrfs.each do |vrf, neighbors|
        if vrf == 'default'
          assert_equal(1, neighbors.size)
        else
          assert_equal(3, neighbors.size)
        end
        neighbors.each_value do |neighbor|
          assert_equal(vrf, neighbor.vrf)
          line = get_bgpneighbor_match_line(neighbor.nbr, vrf)
          refute_nil(line)
        end
      end
    end
  end

  def test_create_destroy
    address = { '1.1.1.1'            => '1.1.1.1',
                '2.2.2.2/24'         => '2.2.2.0/24',
                '2000::2'            => '2000::2',
                '2000:123:38::34/64' => '2000:123:38::/64',
    }
    vrfs = %w(default red)
    vrfs.each do |vrf|
      address.each do |addr, expected_addr|
        neighbor = RouterBgpNeighbor.new(@@asn, vrf, addr)
        line = get_bgpneighbor_match_line(expected_addr, vrf)
        refute_nil(line, "Error: failed to create bgp neighbor #{addr}")
        neighbor.destroy
        line = get_bgpneighbor_match_line(expected_addr, vrf)
        assert_nil(line, "Error: failed to delete bgp neighbor #{addr}")
      end
    end
  end

  def test_description
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      description = "tested by mini test for vrf #{vrf}"
      neighbor.description = description
      assert_equal(description, neighbor.description)
      neighbor.description = ' '
      assert(neighbor.description.empty?)
      neighbor.description = neighbor.default_description
      assert_equal(neighbor.description, neighbor.default_description)
      neighbor.destroy
    end
  end

  def test_multiple_descriptions
    # First create multiple routers with multiple desriptions.
    address = ['1.1.1.1', '2.2.2.0/24', '2000::2', '2000:123:38::/64']
    vrfs = %w(default red)
    vrfs.each do |vrf|
      address.each do |addr|
        neighbor = RouterBgpNeighbor.new(@@asn, vrf, addr)
        neighbor.description = "#{vrf}:#{addr}"
      end
    end
    # Now test if the description has been correctly set
    RouterBgpNeighbor.neighbors.each_value do |bgp_vrfs|
      bgp_vrfs.each do |vrf, neighbors|
        neighbors.each do |addr, neighbor|
          assert_equal("#{vrf}:#{addr}", neighbor.description)
          neighbor.description = ''
          assert(neighbor.description.empty?)
          neighbor.description = neighbor.default_description
          assert_equal(neighbor.description, neighbor.default_description)
          neighbor.destroy
        end
      end
    end
  end

  def test_connected_check
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_connected_check]
      check.each do |value|
        neighbor.connected_check = value
        assert_equal(value, neighbor.connected_check)
      end
      neighbor.destroy
    end
  end

  def test_capability_negotiation
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_capability_negotiation]
      check.each do |value|
        neighbor.capability_negotiation = value
        assert_equal(value, neighbor.capability_negotiation)
      end
      neighbor.destroy
    end
  end

  def test_dynamic_capability
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_dynamic_capability]
      check.each do |value|
        neighbor.dynamic_capability = value
        assert_equal(value, neighbor.dynamic_capability)
      end
      neighbor.destroy
    end
  end

  def test_ebgp_multihop
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      ttls = [24, neighbor.default_ebgp_multihop]
      ttls.each do |ebgp_multihop|
        neighbor.ebgp_multihop = ebgp_multihop
        assert_equal(ebgp_multihop, neighbor.ebgp_multihop)
      end
      neighbor.destroy
    end
  end

  def test_local_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      [42, '52', '1.1', neighbor.default_local_as].each do |asnum|
        neighbor.local_as = asnum
        assert_equal(asnum.to_s, neighbor.local_as)
      end

      # test a negative value
      assert_raises(CliError) do
        neighbor.local_as = '52 15'
      end
      neighbor.destroy
    end
  end

  def test_log_neighbor_changes
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [:enable, :disable, :inherit, 'enable', 'disable', 'inherit',
               neighbor.default_log_neighbor_changes]
      check.each do |value|
        neighbor.log_neighbor_changes = value
        assert_equal(value.to_sym, neighbor.log_neighbor_changes)
      end
      neighbor.destroy
    end
  end

  def test_low_memory_exempt
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_low_memory_exempt]
      check.each do |value|
        neighbor.low_memory_exempt = value
        assert_equal(value, neighbor.low_memory_exempt)
      end
      neighbor.destroy
    end
  end

  def test_maximum_peers
    # only "address/prefix" type of neighbor address will accept
    # maximum_peers command
    addr = '1.1.1.0/24'
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, addr)
      peers = [200, neighbor.default_maximum_peers]
      peers.each do |num|
        neighbor.maximum_peers = num
        assert_equal(num, neighbor.maximum_peers)
      end
      neighbor.destroy
    end
  end

  def test_password
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      passwords = {}
      passwords[:cleartext] = 'test'
      passwords[:"3des"] = '386c0565965f89de'
      passwords[:cisco_type_7] = '046E1803362E595C260E0B240619050A2D'

      passwords.each do |type, password|
        neighbor.password_set(password, type)
        if type == :cleartext
          assert_equal(:"3des", neighbor.password_type)
          assert_equal(passwords[:"3des"], neighbor.password)
        else
          assert_equal(type, neighbor.password_type)
          assert_equal(password, neighbor.password)
        end
        # now test removing the password setting
        neighbor.password_set(' ')
        assert(neighbor.password.empty?)
        # now test default password
        neighbor.password_set(neighbor.default_password)
        assert_equal(neighbor.default_password, neighbor.password)
      end
      neighbor.destroy
    end
  end

  def test_set_default_password_type
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      password = 'test'
      expected_password = '386c0565965f89de'

      # Test 1: if we don't set password type, default should be cleartext,
      # we can verify by checking return type to be :3des, and encrypted text.
      neighbor.password_set(password)
      assert_equal(expected_password, neighbor.password)
      assert_equal(:"3des", neighbor.password_type)
      # clear password
      neighbor.password_set('')
      assert(neighbor.password.empty?)

      # Test 2: we set explicitly the password type to be default password type:
      # cleartext, and verify.
      neighbor.password_set(password, neighbor.default_password_type)
      assert_equal(expected_password, neighbor.password)
      assert_equal(:"3des", neighbor.password_type)
      neighbor.password_set('')
      assert(neighbor.password.empty?)
      neighbor.destroy
    end
  end

  def test_remote_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      [42, '1.1', neighbor.default_remote_as].each do |asnum|
        neighbor.remote_as = asnum
        assert_equal(asnum.to_s, neighbor.remote_as)
      end
      neighbor.destroy
    end
  end

  def test_remove_private_as_options
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      options = [:enable, :disable, :all, :"replace-as", 'enable', 'disable',
                 'all', 'replace-as', neighbor.default_remove_private_as]
      options.each do |option|
        neighbor.remove_private_as = option
        assert_equal(option.to_sym, neighbor.remove_private_as)
      end

      neighbor.remove_private_as = neighbor.default_remove_private_as
      assert_equal(neighbor.default_remove_private_as,
                   neighbor.remove_private_as)
      neighbor.destroy
    end
  end

  def test_shutdown
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_shutdown]
      check.each do |value|
        neighbor.shutdown = value
        assert_equal(value, neighbor.shutdown)
      end
      neighbor.destroy
    end
  end

  def test_suppress_4_byte_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_suppress_4_byte_as]
      check.each do |value|
        neighbor.suppress_4_byte_as = value
        assert_equal(value, neighbor.suppress_4_byte_as)
      end
      neighbor.destroy
    end
  end

  def test_timers
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      timers = [{ keep: 40, hold: 90 },
                { keep: neighbor.default_timers_keepalive,
                  hold: neighbor.default_timers_holdtime },
                { keep: neighbor.default_timers_keepalive,
                  hold: 90 },
                { keep: 40, hold: neighbor.default_timers_holdtime },
               ]
      timers.each do |timer|
        neighbor.timers_set(timer[:keep], timer[:hold])
        assert_equal(timer[:keep], neighbor.timers_keepalive)
        assert_equal(timer[:hold], neighbor.timers_holdtime)
      end
      neighbor.destroy
    end
  end

  def test_transport_passive_only
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      check = [true, false, neighbor.default_transport_passive_only]
      check.each do |value|
        neighbor.transport_passive_only = value
        assert_equal(value, neighbor.transport_passive_only)
      end
      neighbor.destroy
    end
  end

  def test_update_source
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      interfaces = ['loopback1', 'Ethernet1/1', 'ethernet1/1',
                    neighbor.default_update_source]
      interfaces.each do |interface|
        neighbor.update_source = interface
        assert_equal(interface.downcase, neighbor.update_source)
      end
      neighbor.destroy
    end
  end
end
