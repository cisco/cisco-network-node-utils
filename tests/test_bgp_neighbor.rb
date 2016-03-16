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
require_relative '../lib/cisco_node_utils/logger'

# TestBgpNeighbor - Minitest for RouterBgpNeighbor node utility class
class TestBgpNeighbor < CiscoTestCase
  ASN = 55
  ADDR = '1.1.1.1'
  REMOTE_ASN = 99
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_bgps if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
    # BGP Neighbor requires the presence of a basic bgp global config
    RouterBgp.new(ASN)
  end

  def teardown
    remove_all_bgps
    super
  end

  # Returns some test data for use in several tests.
  def test_data
    test_data = []
    test_data << { vrf: 'default', neighbors: ['1.1.1.1'] }

    if platform == :ios_xr
      # XR doesn't support prefix/len addresses
      test_data << { vrf:       'red',
                     neighbors: ['2.2.2.0', '2000::2'] }
    else
      test_data << { vrf:       'red',
                     neighbors: ['2.2.2.0/24', '2000::2', '2000:123:38::/64'] }
    end
  end

  # Finds and returns the neighbor with the specified address
  # and vrf, or nil if it is not found.
  def find_neighbor(addr, vrf='default',
                    bgp_neighbors=RouterBgpNeighbor.neighbors)
    bgp_neighbors.each_value do |vrfs|
      vrfs.each do |vrf_name, neighbors|
        next unless vrf_name == vrf
        neighbors.each_value do |neighbor|
          next unless neighbor.nbr == addr
          Cisco::Logger.debug("neighbor '#{addr}' with vrf '#{vrf}' found")
          return neighbor
        end
      end
    end
    Cisco::Logger.debug("neighbor '#{addr}' with vrf '#{vrf}' not found")
    nil
  end

  # Does the neighbor with the specified address and vrf exist?
  def neighbor_exists?(addr, vrf='default',
                       bgp_neighbors=RouterBgpNeighbor.neighbors)
    find_neighbor(addr, vrf, bgp_neighbors) != nil
  end

  # Finds the neighbor with the specified address in the
  # output from a show cmd.  Returns the matching line of
  # output if found, otherwise nil.
  def get_bgpneighbor_match_line(addr, vrf='default')
    regex = /neighbor #{addr}/
    if vrf == 'default'
      if platform == :ios_xr
        cmd = 'show run router bgp'
        regex = /^ neighbor #{addr}/
      else
        cmd = "show run bgp all | section 'router bgp' | no-more"
      end
    else
      if platform == :ios_xr
        cmd = "show run router bgp #{ASN} vrf #{vrf}"
      else
        cmd = "show run bgp all | section 'vrf #{vrf}' | no-more"
      end
    end
    s = @device.cmd("#{cmd}")
    Cisco::Logger.debug("matching '#{addr}' with vrf '#{vrf}', output: \n#{s}")
    line = regex.match(s)
    Cisco::Logger.debug(line)
    line
  end

  # Creates a neighbor for use in tests, and sets its remote_as.
  def create_neighbor(vrf, addr=ADDR)
    neighbor = RouterBgpNeighbor.new(ASN, vrf, addr)

    # XR requires a remote_as in order to set other properties
    # (description, password, etc.)
    neighbor.remote_as = REMOTE_ASN
    neighbor
  end

  def test_collection_empty
    remove_all_bgps
    neighbors = RouterBgpNeighbor.neighbors
    assert_empty(neighbors, 'BGP neighbor collection is not empty')
  end

  def test_collection_not_empty
    test_data_hash = {}

    cmds = ['router bgp 55']

    test = test_data
    test.each do |d|
      test_data_hash[d[:vrf]] = d[:neighbors]
      cmds << "vrf #{d[:vrf]}" unless d[:vrf] == 'default'
      d[:neighbors].each do |neighbor|
        cmds << "neighbor #{neighbor}" << "remote-as #{REMOTE_ASN}"
      end
    end

    config(*cmds)

    bgp_neighbors = RouterBgpNeighbor.neighbors
    refute_empty(bgp_neighbors, 'BGP neighbor collection is empty')

    # see if all expected neighbors are there
    test.each do |d|
      d[:neighbors].each do |neighbor|
        # see if the neighbor exists in the list returned by the API
        assert(neighbor_exists?(neighbor, d[:vrf], bgp_neighbors),
               'Did not find in neighbor list: '\
               "nbr '#{neighbor}', vrf '#{d[:vrf]}'")

        # see if the neighbor exists via show cmd output
        line = get_bgpneighbor_match_line(neighbor, d[:vrf])
        refute_nil(line, 'Did not find in show output: '\
                   "nbr '#{neighbor}', vrf '#{d[:vrf]}'")
      end
    end
  end

  def test_create_destroy
    test_data.each do |d|
      d[:neighbors].each do |addr|
        neighbor = create_neighbor(d[:vrf], addr)
        exists = neighbor_exists?(addr, d[:vrf])
        assert(exists, "Failed to create bgp neighbor #{addr}")
        line = get_bgpneighbor_match_line(addr, d[:vrf])
        refute_nil(line, "failed to create bgp neighbor #{addr}")
        neighbor.destroy
        exists = neighbor_exists?(addr, d[:vrf])
        refute(exists, "Failed to delete bgp neighbor #{addr}")
        line = get_bgpneighbor_match_line(addr, d[:vrf])
        assert_nil(line, "failed to delete bgp neighbor #{addr}")
      end
    end
  end

  def test_description
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
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
    # First create multiple routers with multiple descriptions.
    test_data.each do |d|
      d[:neighbors].each do |addr|
        neighbor = create_neighbor(d[:vrf], addr)
        neighbor.description = "#{d[:vrf]}:#{addr}"
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
      neighbor = create_neighbor(vrf)
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
      neighbor = create_neighbor(vrf)
      if platform == :ios_xr
        assert_nil(neighbor.capability_negotiation)
        assert_nil(neighbor.default_capability_negotiation)
        assert_raises(Cisco::UnsupportedError) do
          neighbor.capability_negotiation = true
        end
      else
        check = [true, false, neighbor.default_capability_negotiation]
        check.each do |value|
          neighbor.capability_negotiation = value
          assert_equal(value, neighbor.capability_negotiation)
        end
      end
      neighbor.destroy
    end
  end

  def test_dynamic_capability
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      if platform == :ios_xr
        assert_nil(neighbor.dynamic_capability)
        assert_nil(neighbor.default_dynamic_capability)
        assert_raises(Cisco::UnsupportedError) do
          neighbor.dynamic_capability = true
        end
      else
        check = [true, false, neighbor.default_dynamic_capability]
        check.each do |value|
          neighbor.dynamic_capability = value
          assert_equal(value, neighbor.dynamic_capability)
        end
      end
      neighbor.destroy
    end
  end

  def test_ebgp_multihop
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
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
      neighbor = create_neighbor(vrf)
      local_asnum = [42, '52', '1.1', neighbor.default_local_as]
      local_asnum.each do |asnum|
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
    if platform == :ios_xr || node.product_id[/N(5|6|7)/]
      b = create_neighbor('blue')
      assert_nil(b.log_neighbor_changes)
      assert_nil(b.default_log_neighbor_changes)
      assert_raises(Cisco::UnsupportedError) do
        b.log_neighbor_changes = :enable
      end
      return
    end
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
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
      neighbor = create_neighbor(vrf)
      if platform == :ios_xr
        assert_nil(neighbor.low_memory_exempt)
        assert_nil(neighbor.default_low_memory_exempt)
        assert_raises(Cisco::UnsupportedError) do
          neighbor.low_memory_exempt = true
        end
      else
        check = [true, false, neighbor.default_low_memory_exempt]
        check.each do |value|
          neighbor.low_memory_exempt = value
          assert_equal(value, neighbor.low_memory_exempt)
        end
      end
      neighbor.destroy
    end
  end

  def test_maximum_peers
    skip('Maximum-peers does not apply to IOS XR') if platform == :ios_xr

    # only "address/prefix" type of neighbor address will accept
    # maximum_peers command, so not supported on XR
    addr = '1.1.1.0/24'
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf, addr)
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
      neighbor = create_neighbor(vrf)
      passwords = {}
      if platform == :ios_xr
        passwords[:cleartext] = 'test'
        passwords[:md5] = '386c0565965f89de'
        # not currently supporting XR specific 'password inheritance-disable'
      else
        passwords[:cleartext] = 'test'
        passwords[:"3des"] = '386c0565965f89de'
        passwords[:cisco_type_7] = '046E1803362E595C260E0B240619050A2D'
      end

      passwords.each do |type, password|
        neighbor.password_set(password, type)
        if platform == :ios_xr
          if type == :cleartext
            # will always be type "encrypted" on XR
            assert_equal(:md5, neighbor.password_type)
            # don't know what the encrypted password will look like
            # so just make sure it is not empty
            refute_empty(neighbor.password)
          else
            assert_equal(type, neighbor.password_type)
            assert_equal(password, neighbor.password)
          end
        else
          if type == :cleartext
            assert_equal(:"3des", neighbor.password_type)
            assert_equal(passwords[:"3des"], neighbor.password)
          else
            assert_equal(type, neighbor.password_type)
            assert_equal(password, neighbor.password)
          end
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

  def test_default_password_type
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      password = 'test'
      expected_password = '386c0565965f89de'

      test = proc do
        if platform == :ios_xr
          assert_equal(:md5, neighbor.password_type)
          refute_empty(neighbor.password)
        else
          assert_equal(expected_password, neighbor.password)
          assert_equal(:"3des", neighbor.password_type)
        end
        # clear password
        neighbor.password_set('')
        assert(neighbor.password.empty?)
      end

      # Test 1: if we don't set password type, default should be cleartext,
      # we can verify by checking return type to be
      # :3des/:md5, and encrypted text.
      neighbor.password_set(password)
      test.call

      # Test 2: we set explicitly the password type to be default password type:
      # cleartext, and verify.
      neighbor.password_set(password, neighbor.default_password_type)
      test.call
      neighbor.destroy
    end
  end

  def test_remote_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(ASN, vrf, ADDR)
      [42, '1.1', neighbor.default_remote_as].each do |asnum|
        neighbor.remote_as = asnum
        assert_equal(asnum.to_s, neighbor.remote_as)
      end
      neighbor.destroy
    end
  end

  def test_remove_private_as_options
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      if platform == :ios_xr
        assert_nil(neighbor.remove_private_as)
        assert_nil(neighbor.default_remove_private_as)
        assert_raises(Cisco::UnsupportedError) do
          neighbor.remove_private_as = :enable
        end
      else
        options = [:enable, :disable, :all, :"replace-as", 'enable', 'disable',
                   'all', 'replace-as', neighbor.default_remove_private_as]

        options.each do |option|
          neighbor.remove_private_as = option
          assert_equal(option.to_sym, neighbor.remove_private_as)
        end

        neighbor.remove_private_as = neighbor.default_remove_private_as
        assert_equal(neighbor.default_remove_private_as,
                     neighbor.remove_private_as)
      end
      neighbor.destroy
    end
  end

  def test_shutdown
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
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
      neighbor = create_neighbor(vrf)
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
      neighbor = create_neighbor(vrf)
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

  def test_transport_passive_mode
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      check = []
      if platform == :ios_xr
        check = [:active_only, :passive_only, :both, :none,
                 neighbor.default_transport_passive_mode]
      else
        check = [:passive_only, :none,
                 neighbor.default_transport_passive_mode]
      end
      check.each do |value|
        neighbor.transport_passive_mode = value
        assert_equal(value, neighbor.transport_passive_mode)
      end
      neighbor.destroy
    end
  end

  def test_transport_passive_only
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
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
      neighbor = create_neighbor(vrf)
      test_interfaces = ['loopback1', interfaces[0], interfaces[0].downcase,
                         neighbor.default_update_source]
      test_interfaces.each do |interface|
        neighbor.update_source = interface
        assert_equal(interface.downcase, neighbor.update_source)
      end
      neighbor.destroy
    end
  end
end
