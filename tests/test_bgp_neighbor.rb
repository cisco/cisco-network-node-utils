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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/bgp'
require_relative '../lib/cisco_node_utils/bgp_neighbor'

# TestRouterBgpNeighbor - Minitest for RouterBgpNeighbor node utility class
class TestRouterBgpNeighbor < CiscoTestCase
  # rubocop:disable Style/ClassVars
  @@asn = 55
  @@addr = '1.1.1.1'
  @@remote_asn = 99

  # some test data for use in several tests
  @@test_data = []
  @@test_data << { vrf: 'default', neighbors: ['1.1.1.1'] }
  @@test_data << { vrf:       'red',
                   neighbors: ['2.2.2.0', '2000::2', '2000:123:38::'] }
  # was 2.2.2.0/24 and 2000:123:38::/64
  # rubocop:enable Style/ClassVars

  def setup
    # Disable feature bgp before each test to ensure we
    # are starting with a clean slate for each test.
    super
    if platform == :ios_xr
      config('no router bgp', 'router bgp 55')
    else
      config('no feature bgp', 'feature bgp', 'router bgp 55')
    end
  end

  def teardown
    disable_bgp
  end

  def disable_bgp
    if platform == :ios_xr
      config('no router bgp')
    else
      config('no feature bgp')
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
          CiscoLogger.debug("neighbor '#{addr}' with vrf '#{vrf}' found")
          return neighbor
        end
      end
    end
    CiscoLogger.debug("neighbor '#{addr}' with vrf '#{vrf}' not found")
    nil
  end

  # Does the neighbor with the specified address and vrf exist?
  def neighbor_exists?(addr, vrf='default',
                       bgp_neighbors=RouterBgpNeighbor.neighbors)
    find_neighbor(addr, vrf, bgp_neighbors) != nil
  end

  # Creates a neighbor for use in tests, and sets its remote_as.
  def create_neighbor(vrf, addr=@@addr)
    neighbor = RouterBgpNeighbor.new(@@asn, vrf, addr)

    # XR requires a remote_as in order to set other properties
    # (description, password, etc.)
    neighbor.remote_as = @@remote_asn
    neighbor
  end

  def test_collection_empty
    disable_bgp
    neighbors = RouterBgpNeighbor.neighbors
    assert_empty(neighbors, 'BGP neighbor collection is not empty')
  end

  def test_collection_not_empty
    test_data_hash = {}

    cmds = ['router bgp 55']
    @@test_data.each do |d|
      test_data_hash[d[:vrf]] = d[:neighbors]
      cmds << "vrf #{d[:vrf]}" unless d[:vrf] == 'default'
      d[:neighbors].each do |neighbor|
        cmds << "neighbor #{neighbor}"
      end
    end

    config(*cmds)

    bgp_neighbors = RouterBgpNeighbor.neighbors
    refute_empty(bgp_neighbors, 'BGP neighbor collection is empty')

    # see if all expected neighbors are there
    @@test_data.each do |d|
      d[:neighbors].each do |neighbor|
        assert(neighbor_exists?(neighbor, d[:vrf], bgp_neighbors),
               "Did not find match for nbr '#{neighbor}', vrf '#{d[:vrf]}'")
      end
    end
  end

  def test_create_destroy
    @@test_data.each do |d|
      d[:neighbors].each do |addr|
        neighbor = RouterBgpNeighbor.new(@@asn, d[:vrf], addr)
        exists = neighbor_exists?(addr, d[:vrf])
        assert(exists, "Failed to create bgp neighbor #{addr}")
        neighbor.destroy
        exists = neighbor_exists?(addr, d[:vrf])
        refute(exists, "Failed to delete bgp neighbor #{addr}")
      end
    end
  end

  def test_set_get_description
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

  def test_set_get_multiple_descriptions
    # First create multiple routers with multiple descriptions.
    @@test_data.each do |d|
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

  def test_set_get_connected_check
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

  def test_set_get_capability_negotiation
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      check = []
      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          check = [true, false, neighbor.default_capability_negotiation]
        end
      else
        check = [true, false, neighbor.default_capability_negotiation]
      end
      check.each do |value|
        neighbor.capability_negotiation = value
        assert_equal(value, neighbor.capability_negotiation)
      end
      neighbor.destroy
    end
  end

  def test_set_get_dynamic_capability
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      check = []
      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          check = [true, false, neighbor.default_dynamic_capability]
        end
      else
        check = [true, false, neighbor.default_dynamic_capability]
      end
      check.each do |value|
        neighbor.dynamic_capability = value
        assert_equal(value, neighbor.dynamic_capability)
      end
      neighbor.destroy
    end
  end

  def test_set_get_ebgp_multihop
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

  def test_set_get_local_as
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      local_asnum = [42, '52', '1.1', neighbor.default_local_as]
      local_asnum.each do |asnum|
        neighbor.local_as = asnum
        if asnum == '52'
          assert_equal(asnum.to_i, neighbor.local_as)
        else
          assert_equal(asnum, neighbor.local_as)
        end
      end
      # test a negative value
      assert_raises(ArgumentError) do
        neighbor.local_as = '52 15'
      end
      neighbor.destroy
    end
  end

  def test_set_get_log_neighbor_changes
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)

      check = []
      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          check = [:enable, :disable, :inherit, 'enable', 'disable', 'inherit',
                   neighbor.default_log_neighbor_changes]
        end
      else
        check = [:enable, :disable, :inherit, 'enable', 'disable', 'inherit',
                 neighbor.default_log_neighbor_changes]
      end

      check.each do |value|
        neighbor.log_neighbor_changes = value
        assert_equal(value.to_sym, neighbor.log_neighbor_changes)
      end
      neighbor.destroy
    end
  end

  def test_set_get_low_memory_exempt
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      check = []
      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          check = [true, false, neighbor.default_low_memory_exempt]
        end
      else
        check = [true, false, neighbor.default_low_memory_exempt]
      end
      check.each do |value|
        neighbor.low_memory_exempt = value
        assert_equal(value, neighbor.low_memory_exempt)
      end
      neighbor.destroy
    end
  end

  def test_set_get_maximum_peers
    # XR doesn't allow "address/prefix" type addresses
    if platform == :ios_xr
      fail Cisco::UnsupportedError.new('bgp_neighbor', 'maximum_peers')
    end

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

  def test_set_get_password
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      passwords = {}
      if platform == :ios_xr
        passwords[:clear] = 'test'
        passwords[:encrypted] = '386c0565965f89de'
        # not currently supporting XR specific 'password inheritance-disable'
      else
        passwords[:cleartext] = 'test'
        passwords[:"3des"] = '386c0565965f89de'
        passwords[:cisco_type_7] = '046E1803362E595C260E0B240619050A2D'
      end

      passwords.each do |type, password|
        neighbor.password_set(password, type)
        if platform == :ios_xr
          if type == :clear
            # will always be type "encrypted" on XR
            assert_equal(:encrypted, neighbor.password_type)
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

  def test_set_default_password_type
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      password = 'test'
      expected_password = '386c0565965f89de'

      test = proc do
        if platform == :ios_xr
          assert_equal(:encrypted, neighbor.password_type)
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
      # :3des/:encrypted, and encrypted text.
      neighbor.password_set(password)
      test.call

      # Test 2: we set explicitly the password type to be default password type:
      # cleartext, and verify.
      neighbor.password_set(password, neighbor.default_password_type)
      test.call

      neighbor.destroy
    end
  end

  def test_set_get_remote_as
    %w(default test_vrf).each do |vrf|
      neighbor = RouterBgpNeighbor.new(@@asn, vrf, @@addr)
      remote_asnum = [42, '1.1', neighbor.default_remote_as]
      remote_asnum.each do |asnum|
        neighbor.remote_as = asnum
        assert_equal(asnum, neighbor.remote_as)
      end
      neighbor.destroy
    end
  end

  def test_set_get_remove_private_as_options
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      options = []
      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          options = [:enable, :disable, :all, :"replace-as", 'enable',
                     'disable', 'all', 'replace-as',
                     neighbor.default_remove_private_as]
        end
      else
        options = [:enable, :disable, :all, :"replace-as", 'enable', 'disable',
                   'all', 'replace-as', neighbor.default_remove_private_as]
      end
      options.each do |option|
        neighbor.remove_private_as = option
        assert_equal(option.to_sym, neighbor.remove_private_as)
      end

      if platform == :ios_xr
        assert_raises(Cisco::UnsupportedError) do
          neighbor.remove_private_as = neighbor.default_remove_private_as
        end
      else
        neighbor.remove_private_as = neighbor.default_remove_private_as
        assert_equal(neighbor.default_remove_private_as,
                     neighbor.remove_private_as)
      end
      neighbor.destroy
    end
  end

  def test_set_get_shutdown
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

  def test_set_get_suppress_4_byte_as
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

  def test_set_get_timers
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

  def test_set_get_transport_passive_mode
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)
      check = []
      if platform == :ios_xr
        check = [:active_only, :passive_only, :both,
                 neighbor.default_transport_passive_mode]
      else
        check = [:passive_only, :both, neighbor.default_transport_passive_mode]
      end
      check.each do |value|
        neighbor.transport_passive_mode = value
        assert_equal(value, neighbor.transport_passive_mode)
      end
      neighbor.destroy
    end
  end

  def test_set_get_transport_passive_only
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

  def test_set_get_update_source
    %w(default test_vrf).each do |vrf|
      neighbor = create_neighbor(vrf)

      interfaces = []

      if platform == :ios_xr
        interfaces = ['loopback1',
                      'GigabitEthernet0/0/0/0',
                      'gigabitethernet0/0/0/0',
                      neighbor.default_update_source]
      else
        interfaces = ['loopback1', 'Ethernet1/1', 'ethernet1/1',
                      neighbor.default_update_source]
      end

      interfaces.each do |interface|
        neighbor.update_source = interface
        assert_equal(interface.downcase, neighbor.update_source)
      end
      neighbor.destroy
    end
  end
end
