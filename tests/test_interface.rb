# Copyright (c) 2013-2015 Cisco and/or its affiliates.
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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/interface', __FILE__)

include Cisco

# TestInterface - Minitest for general functionality of the Interface class.
class TestInterface < CiscoTestCase
  # rubocop:disable Style/AlignHash
  SWITCHPORT_SHUTDOWN_HASH = {
    'shutdown_ethernet_switchport_shutdown'     =>
      ['system default switchport', 'system default switchport shutdown'],
    'shutdown_ethernet_switchport_noshutdown'   =>
      ['system default switchport', 'no system default switchport shutdown'],
    'shutdown_ethernet_noswitchport_shutdown'   =>
      ['no system default switchport', 'system default switchport shutdown'],
    'shutdown_ethernet_noswitchport_noshutdown' =>
      ['no system default switchport', 'no system default switchport shutdown'],
  }
  # rubocop:enable Style/AlignHash

  DEFAULT_IF_ACCESS_VLAN = 1
  DEFAULT_IF_DESCRIPTION = ''
  DEFAULT_IF_IP_ADDRESS = nil
  DEFAULT_IF_IP_NETMASK_LEN = nil
  DEFAULT_IF_IP_PROXY_ARP = false
  DEFAULT_IF_IP_REDIRECTS = true
  DEFAULT_IF_VRF = ''
  IF_DESCRIPTION_SIZE = 243 # SIZE = VSH Max 255 - "description " keyword
  IF_VRF_MAX_LENGTH = 32

  def interface_ipv4_config(ifname, address, length,
                            config=true, secip=false)
    @device.cmd('configure terminal')
    @device.cmd("interface #{ifname}")
    if config == true
      @device.cmd('no switchport')
      @device.cmd("ip address #{address}/#{length}") if secip != true
      @device.cmd("ip address #{address}/#{length} secondary") if secip == true
    else
      # This will remove both primary and secondary
      @device.cmd('no ip address')
      @device.cmd('switchport')
    end
    @device.cmd('end')
    node.cache_flush
  end

  def get_interface_match_line(name, pattern)
    s = @device.cmd("show run interface #{name} all | no-more")
    line = pattern.match(s)
    line
  end

  def interface_count
    output = @device.cmd('show run interface all | inc interface | no-more')
    # Next line needs to be done because sh run interface all also shows
    # ospf interface related config
    arr = output.split("\n").select { |str| str.start_with?('interface') }
    arr.count
  end

  def create_interface(ifname=interfaces[0])
    Interface.new(ifname)
  end

  def interface_ethernet_default(ethernet_id)
    @device.cmd('configure terminal')
    @device.cmd("default interface ethernet #{ethernet_id}")
    @device.cmd('end')
    node.cache_flush
  end

  def validate_interfaces_not_empty
    interfaces = Interface.interfaces
    refute_empty(interfaces, 'Error: interfaces collection empty')

    # Get number of interfaces
    int_size = interface_count
    assert_equal(int_size, interfaces.size,
                 'Error: Interfaces collection size not correct')
  end

  def system_default_switchport_shutdown
    state = []
    s = @device.cmd("sh run all | in \"system default switchport\"")

    s.split("\n")[1..-2].each do |line|
      state << line unless line.include?('fabricpath')
    end
    state
  end

  def system_default_switchport_shutdown_set(state)
    @device.cmd('configure terminal')
    state.each { |config_line| @device.cmd(config_line) }
    @device.cmd('end')
    node.cache_flush
  end

  def validate_interface_shutdown(inttype_h)
    state = system_default_switchport_shutdown

    # Validate the collection
    inttype_h.each do |k, v|
      interface = v[:interface]

      SWITCHPORT_SHUTDOWN_HASH.each do |lookup_string, config_array|
        # puts "lookup_string: #{lookup_string}"

        # Configure the system default shwitchport and shutdown settings
        system_default_switchport_shutdown_set(config_array)

        interface.shutdown = false
        refute(interface.shutdown, "Error: #{interface.name} shutdown is not false")

        interface.shutdown = true
        assert(interface.shutdown, "Error: #{interface.name} shutdown is not true")

        # Test default shutdown state
        if k.downcase.include?('ethernet') # Ethernet interfaces

          ref = cmd_ref.lookup('interface', lookup_string)
          assert(ref, "Error, reference not found for #{lookup_string}")

          result = interface.default_shutdown
          assert_equal(ref.default_value, result, "Error: #{interface.name}, " \
                       "(#{lookup_string}), shutdown is #{result}, incorrect")
        else # Port-channel and loopback interfaces
          assert_equal(interface.default_shutdown, v[:default_shutdown],
                       "default shutdown state (#{lookup_string}), incorrect")
        end
      end
    end
    system_default_switchport_shutdown_set(state)
  end

  # set_switchport is handled else where since it changes the
  # interface to L2 and that would affect the idea of this test.
  def validate_get_switchport(inttype_h)
    # Validate the collection
    inttype_h.each_value do |v|
      interface = v[:interface]

      # Adding a check for getting the switchport_mode on a interfaces
      # that does not support switchport. This used to fail with
      # exception and was first found in end-to-end testing due to how
      # the provider, by default, invokes the getter methods for an
      # interface.
      assert_equal(v[:switchport],
                   interface.switchport_mode,
                   "Error: #{interface.name}, switchport mode not correct")

      # get_default check
      assert_equal(v[:default_switchport],
                   interface.default_switchport_mode,
                   "Error: #{interface.name}, switchport mode, default, not correct")
    end
  end

  def validate_description(inttype_h)
    # Validate the description
    inttype_h.each_value do |v|
      interface = v[:interface]

      # Check of description
      assert_equal(v[:description], interface.description,
                   "Error: [#{interface.name}] Description is not configured")

      # Change description
      interface.description = v[:description_new]
      assert_equal(v[:description_new], interface.description,
                   "Error: [#{interface.name}] Description is not changed")

      # get_default check
      assert_equal(v[:default_description], interface.default_description,
                   "Error: [#{interface.name}] Default description is not configured")
    end
  end

  def validate_get_access_vlan(inttype_h)
    # Validate the collection
    inttype_h.each_value do |v|
      interface = v[:interface]

      assert_equal(v[:access_vlan], interface.access_vlan,
                   'Error: Access vlan value not correct')

      # get_default check
      assert_equal(v[:default_access_vlan], interface.default_access_vlan,
                   'Error: Access vlan, default,  value not correct')
    end
  end

  def validate_ipv4_address(inttype_h)
    # Validate the collection
    inttype_h.each do |k, v|
      interface = v[:interface]

      # Verify existing value
      address = v[:address_len].split('/').first
      length = v[:address_len].split('/').last.to_i

      pattern = %r{^\s+ip address #{address}/#{length}}
      line = get_interface_match_line(interface.name, pattern)

      refute_nil(line, "Error: ipv4 address #{address}/#{length} " \
                 "missing in CLI for #{k}")
      assert_equal(address, interface.ipv4_address,
                   "Error: ipv4 address get value mismatch for #{k}")
      assert_equal(length, interface.ipv4_netmask_length,
                   "Error: ipv4 netmask length get value mismatch for #{k}")

      # Get default
      assert_equal(DEFAULT_IF_IP_ADDRESS, interface.default_ipv4_address,
                   "Error: ipv4 address get default value mismatch for #{k}")

      # get_default_netmask
      assert_equal(DEFAULT_IF_IP_NETMASK_LEN,
                   interface.default_ipv4_netmask_length,
                   "Error: ipv4 netmask length default mismatch for #{k}")

      # Unconfigure ipaddress
      interface.ipv4_addr_mask_set(interface.default_ipv4_address,
                                   interface.default_ipv4_netmask_length)
      pattern = %r{^\s+ip address #{address}/#{length}}
      line = get_interface_match_line(interface.name, pattern)

      assert_nil(line, "Error: ipv4 address still present in CLI for #{k}")
      assert_equal(DEFAULT_IF_IP_ADDRESS, interface.ipv4_address,
                   "Error: ipv4 address value mismatch after unconfig for #{k}")
      assert_equal(DEFAULT_IF_IP_NETMASK_LEN,
                   interface.ipv4_netmask_length,
                   "Error: ipv4 netmask length default mismatch for #{k}")
    end
  end

  def validate_ipv4_proxy_arp(inttype_h)
    # Validate the collection
    inttype_h.each do |k, v|
      # Skipping loopback, proxy arp not supported
      next if (k == 'loopback0')

      interface = v[:interface]

      # puts "value - #{v[:proxy_arp]}"
      pattern = (/^\s+ip proxy-arp/)
      line = get_interface_match_line(interface.name, pattern)
      # puts line
      assert_equal(!v[:proxy_arp], line.nil?,
                   'Error: ip proxy-arp enable missing in CLI')
      assert_equal(v[:proxy_arp], interface.ipv4_proxy_arp,
                   "Error: ip proxy-arp get value 'true' mismatch")

      # puts "value reverse- #{!v[:proxy_arp]}"
      interface.ipv4_proxy_arp = !v[:proxy_arp]
      line = get_interface_match_line(interface.name, pattern)
      assert_equal(v[:proxy_arp], line.nil?,
                   'Error: ip proxy-arp disable missing in CLI')
      assert_equal(!v[:proxy_arp], interface.ipv4_proxy_arp,
                   "Error: ip proxy-arp get value 'false' mismatch")

      # Get default
      assert_equal(DEFAULT_IF_IP_PROXY_ARP,
                   interface.default_ipv4_proxy_arp,
                   'Error: ip proxy arp get default value mismatch')

      # Get default and set
      interface.ipv4_proxy_arp = interface.default_ipv4_proxy_arp
      line = get_interface_match_line(interface.name, pattern)
      assert_nil(line, 'Error: default ip proxy-arp set failed')
      assert_equal(DEFAULT_IF_IP_PROXY_ARP,
                   interface.ipv4_proxy_arp,
                   'Error: ip proxy-arp default get value mismatch')
    end
  end

  def validate_ipv4_redirects(inttype_h)
    # Validate the collection
    inttype_h.each do |k, v|
      interface = v[:interface]

      if k.include?('loopback')
        lookup_name = 'ipv4_redirects_loopback'
      else
        lookup_name = 'ipv4_redirects_other_interfaces'
      end

      ref = cmd_ref.lookup('interface', lookup_name)
      assert(ref, 'Error, reference not found')

      # Check default
      assert_equal(ref.default_value, interface.default_ipv4_redirects,
                   "ipv4 redirects default incorrect for interface #{k}")

      begin
        config_set = ref.config_set
      rescue IndexError
        config_set = nil
      end

      if config_set
        pattern = ref.test_config_get_regex[0]

        if k.include?('loopback')
          assert_raises(Cisco::CliError) { interface.ipv4_redirects = true }
        else
          interface.ipv4_redirects = true
          assert(interface.ipv4_redirects, "Couldn't set redirects to true")
          line = get_interface_match_line(interface.name, pattern)
          assert_nil(line, "Error: #{k} ipv4_redirects cfg mismatch")

          interface.ipv4_redirects = false
          refute(interface.ipv4_redirects, "Couldn't set redirects to false")
          line = get_interface_match_line(interface.name, pattern)
          refute_nil(line, "Error: #{k} ipv4_redirects cfg mismatch")
        end
      else
        # Getter should return same value as default if setter isn't supported
        assert_equal(interface.ipv4_redirects, interface.default_ipv4_redirects,
                     'ipv4 redirects default incorrect')

        # Make sure setter fails
        assert_raises(ref.test_config_result(true)) do
          interface.ipv4_redirects = true
        end
        assert_raises(ref.test_config_result(false)) do
          interface.ipv4_redirects = false
        end
      end
    end
  end

  def validate_vrf(inttype_h)
    # Validate the vrf
    inttype_h.each_value do |v|
      interface = v[:interface]

      # Change vrf
      interface.vrf = v[:vrf_new]
      assert_equal(v[:vrf_new], interface.vrf,
                   "Error: [#{interface.name}] vrf is not changed")

      # Set to default vrf
      assert_equal(v[:default_vrf], interface.default_vrf,
                   "Error: [#{interface.name}] vrf config found. Should be default vrf")
    end
  end

  def test_interface_create_name_nil
    assert_raises(TypeError) do
      Interface.new(nil)
    end
  end

  def test_interface_create_name_invalid
    assert_raises(TypeError) do
      Interface.new(node)
    end
  end

  def test_interface_create_does_not_exist
    assert_raises(CliError) do
      Interface.new('bogus')
    end
  end

  def test_interface_create_valid
    interface = Interface.new(interfaces[0])
    assert_equal(interfaces[0].downcase, interface.name)
  end

  def test_interface_description_nil
    interface = Interface.new(interfaces[0])
    assert_raises(TypeError) do
      interface.description = nil
    end
  end

  def test_interface_description_zero_length
    interface = Interface.new(interfaces[0])
    interface.description = ''
    assert_equal('', interface.description)
  end

  def test_interface_description_too_long
    interface = Interface.new(interfaces[0])
    description = 'a' * (IF_DESCRIPTION_SIZE + 1)
    assert_raises(RuntimeError) { interface.description = description }
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_description_valid
    interface = Interface.new(interfaces[0])
    alphabet = 'abcdefghijklmnopqrstuvwxyz 0123456789'
    description = ''
    1.upto(IF_DESCRIPTION_SIZE) do |i|
      description += alphabet[i % alphabet.size, 1]
      next unless i == IF_DESCRIPTION_SIZE
      # puts("description (#{i}): #{description}")
      interface.description = description
      assert_equal(description.rstrip, interface.description)
    end
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_encapsulation_dot1q_change
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    subif = Interface.new(interfaces[0] + '.1')

    subif.encapsulation_dot1q = 20
    assert_equal(20, subif.encapsulation_dot1q)
    subif.encapsulation_dot1q = 25
    assert_equal(25, subif.encapsulation_dot1q)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_encapsulation_dot1q_invalid
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    subif = Interface.new(interfaces[0] + '.1')

    assert_raises(RuntimeError) { subif.encapsulation_dot1q = 'hello' }
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_encapsulation_dot1q_valid
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    subif = Interface.new(interfaces[0] + '.1')

    subif.encapsulation_dot1q = 20
    assert_equal(20, subif.encapsulation_dot1q)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_mtu_change
    interface = Interface.new(interfaces[0])
    interface.mtu = 1490
    assert_equal(1490, interface.mtu)
    interface.mtu = 580
    assert_equal(580, interface.mtu)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_mtu_invalid
    interface = Interface.new(interfaces[0])
    assert_raises(RuntimeError) { interface.mtu = 'hello' }
  end

  def test_interface_mtu_valid
    interface = Interface.new(interfaces[0])
    interface.mtu = 1490
    assert_equal(1490, interface.mtu)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_shutdown_valid
    interface = Interface.new(interfaces[0])
    interface.shutdown = true
    assert(interface.shutdown, 'Error: shutdown state is not true')

    interface.shutdown = false
    refute(interface.shutdown, 'Error: shutdown state is not false')
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_get_access_vlan
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    interface.switchport_mode = :access
    assert_equal(DEFAULT_IF_ACCESS_VLAN, interface.access_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_get_access_vlan_switchport_disabled
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    assert_equal(DEFAULT_IF_ACCESS_VLAN, interface.access_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_get_access_vlan_switchport_trunk
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    interface.switchport_mode = :trunk
    assert_equal(DEFAULT_IF_ACCESS_VLAN, interface.access_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  #   def test_interface_get_prefix_list_when_switchport
  #     interface = Interface.new(interfaces[0])
  #     interface.switchport_mode = :access
  #     addresses = interface.prefixes
  #     assert_empty(addresses)
  #     interface_ethernet_default(interfaces_id[0])
  #   end
  #
  #   def test_interface_get_prefix_list_with_ipv4_address_assignment
  #     interface = Interface.new(interfaces[0])
  #     interface.switchport_mode = :access
  #     interface.switchport_mode = :disabled
  #     @device.cmd("configure terminal")
  #     @device.cmd("interface #{interfaces[0]}")
  #     @device.cmd("ip address 192.168.1.100 255.255.255.0")
  #     @device.cmd("end")
  #     node.cache_flush
  #     prefixes = interface.prefixes
  #     assert_equal(1, prefixes.size)
  #     assert(prefixes.has_key?("192.168.1.100"))
  #     interface.switchport_mode = :access
  #     prefixes = nil
  #     interface_ethernet_default(interfaces_id[0])
  #   end
  #
  #   def test_interface_get_prefix_list_with_ipv6_address_assignment
  #     interface = Interface.new(interfaces[0] )
  #     interface.switchport_mode = :access
  #     interface.switchport_mode = :disabled
  #     @device.cmd("configure terminal")
  #     @device.cmd("interface #{interfaces[0]}")
  #     @device.cmd("ipv6 address fd56:31f7:e4ad:5585::1/64")
  #     @device.cmd("end")
  #     node.cache_flush
  #     prefixes = interface.prefixes
  #     assert_equal(2, prefixes.size)
  #     assert(prefixes.has_key?("fd56:31f7:e4ad:5585::1"))
  #     interface.switchport_mode = :access
  #     prefixes = nil
  #     interface_ethernet_default(interfaces_id[0])
  #   end
  #
  #   def test_interface_get_prefix_list_with_both_ip4_and_ipv6_address_assignments
  #     interface = Interface.new(interfaces[0])
  #     interface.switchport_mode = :access
  #     interface.switchport_mode = :disabled
  #     @device.cmd("configure terminal")
  #     @device.cmd("interface #{interfaces[0]}")
  #     @device.cmd("ip address 192.168.1.100 255.255.255.0")
  #     @device.cmd("ipv6 address fd56:31f7:e4ad:5585::1/64")
  #     @device.cmd("end")
  #     node.cache_flush
  #     prefixes = interface.prefixes
  #     assert_equal(3, prefixes.size)
  #     assert(prefixes.has_key?("192.168.1.100"))
  #     assert(prefixes.has_key?("fd56:31f7:e4ad:5585::1"))
  #     interface.switchport_mode = :access
  #     prefixes = nil
  #     interface_ethernet_default(interfaces_id[0])
  #   end

  def negotiate_auto_helper(interface, default, cmd_ref)
    inf_name = interface.name

    # Test default
    assert_equal(default, interface.default_negotiate_auto,
                 "Error: #{inf_name} negotiate auto default value mismatch")

    begin
      config_set = cmd_ref.config_set
    rescue IndexError
      config_set = nil
    end

    if config_set
      # Skip test if cli not supported on interface
      @device.cmd("conf t; interface #{interface}")
      s = @device.cmd('negotiate auto')
      unless s[/% Invalid command/]

        interface.negotiate_auto = true
        assert_equal(interface.negotiate_auto, true,
                     "Error: #{inf_name} negotiate auto value not true")

        pattern = cmd_ref.test_config_get_regex[0]
        line = get_interface_match_line(interface.name, pattern)
        # TODO: needs to get the result from cmd_ref.test_config_get_result[0]
        assert_nil(line, "Error: #{inf_name} no negotiate auto cfg mismatch")

        pattern = cmd_ref.test_config_get_regex[1]
        line = get_interface_match_line(interface.name, pattern)
        refute_nil(line, "Error: #{inf_name} negotiate auto cfg mismatch")

        interface.negotiate_auto = false
        refute(interface.negotiate_auto,
               "Error: #{inf_name} negotiate auto value not false")

        pattern = cmd_ref.test_config_get_regex[0]
        line = get_interface_match_line(interface.name, pattern)
        refute_nil(line, "Error: #{inf_name} no negotiate auto cfg mismatch")
      end
    else
      # check the get
      assert_equal(interface.negotiate_auto, default,
                   "Error: #{inf_name} negotiate auto value should be same as default")

      # check the set for unsupported platforms
      assert_raises(RuntimeError) do
        interface.negotiate_auto = true
      end
    end
  end

  def test_negotiate_auto_portchannel
    ref = cmd_ref.lookup('interface',
                         'negotiate_auto_portchannel')
    assert(ref, 'Error, reference not found')

    inf_name = 'port-channel10'
    @device.cmd('configure terminal')
    @device.cmd('interface port-channel 10')
    @device.cmd('end')
    node.cache_flush
    interface = Interface.new(inf_name)
    default = ref.default_value

    # Test with switchport
    negotiate_auto_helper(interface, default, ref)

    # Test with no switchport
    @device.cmd('configure terminal')
    @device.cmd('interface port-channel 10')
    @device.cmd('no switchport')
    @device.cmd('end')
    node.cache_flush
    negotiate_auto_helper(interface, default, ref)

    # Cleanup
    @device.cmd('configure terminal')
    @device.cmd('no interface port-channel 10')
    @device.cmd('end')
    node.cache_flush
  end

  def test_negotiate_auto_ethernet
    ref = cmd_ref.lookup('interface',
                         'negotiate_auto_ethernet')
    assert(ref, 'Error, reference not found')

    # Some platforms does not support negotiate auto
    # if so then we abort the test.

    inf_name = interfaces[0]
    interface = Interface.new(inf_name)
    default = ref.default_value

    # Test with switchport
    negotiate_auto_helper(interface, default, ref)

    # Test with no switchport
    @device.cmd('configure terminal')
    @device.cmd("interface #{interfaces[0]}")
    @device.cmd('no switchport')
    @device.cmd('end')
    node.cache_flush
    negotiate_auto_helper(interface, default, ref)

    # Cleanup
    interface_ethernet_default(interfaces_id[0])
    node.cache_flush
  end

  def test_negotiate_auto_loopback
    ref = cmd_ref.lookup('interface',
                         'negotiate_auto_other_interfaces')
    assert(ref, 'Error, reference not found')

    inf_name = 'loopback2'
    @device.cmd('configure terminal')
    @device.cmd('interface loopback 2')
    @device.cmd('end')
    node.cache_flush
    interface = Interface.new(inf_name)

    assert_equal(interface.negotiate_auto, ref.default_value,
                 "Error: #{inf_name} negotiate auto value mismatch")

    assert_raises(ref.test_config_result(true)) do
      interface.negotiate_auto = true
    end
    assert_raises(ref.test_config_result(false)) do
      interface.negotiate_auto = false
    end

    # Cleanup
    @device.cmd('configure terminal')
    @device.cmd('no interface loopback 2')
    @device.cmd('end')
    node.cache_flush
  end

  def test_interfaces_not_empty
    refute_empty(Interface.interfaces, 'Error: interfaces collection empty')
  end

  def test_interface_ipv4_addr_mask_set_address_invalid
    interface = create_interface
    interface.switchport_mode = :disabled
    assert_raises(RuntimeError) do
      interface.ipv4_addr_mask_set('', 14)
    end
    interface.switchport_mode = :access
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_ipv4_addr_mask_set_netmask_invalid
    interface = create_interface
    interface.switchport_mode = :disabled
    assert_raises(RuntimeError) do
      interface.ipv4_addr_mask_set('8.1.1.2', DEFAULT_IF_IP_NETMASK_LEN)
    end
    interface.switchport_mode = :access
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_ipv4_address
    interface = create_interface
    interface.switchport_mode = :disabled
    address = '8.7.1.1'
    length = 15

    # setter, getter
    interface.ipv4_addr_mask_set(address, length)
    pattern = %r{^\s+ip address #{address}/#{length}}
    line = get_interface_match_line(interface.name, pattern)
    refute_nil(line, 'Error: ipv4 address missing in CLI')
    assert_equal(address, interface.ipv4_address,
                 'Error: ipv4 address get value mismatch')
    assert_equal(length, interface.ipv4_netmask_length,
                 'Error: ipv4 netmask length get value mismatch')
    # get default
    assert_equal(DEFAULT_IF_IP_ADDRESS, interface.default_ipv4_address,
                 'Error: ipv4 address get default value mismatch')

    # get_default_netmask
    assert_equal(DEFAULT_IF_IP_NETMASK_LEN,
                 interface.default_ipv4_netmask_length,
                 'Error: ipv4 netmask length get default value mismatch')

    # unconfigure ipaddress
    interface.ipv4_addr_mask_set(interface.default_ipv4_address, length)
    pattern = (/^\s+ip address (.*)/)
    line = get_interface_match_line(interface.name, pattern)
    assert_nil(line, 'Error: ipv4 address still present in CLI')
    assert_equal(DEFAULT_IF_IP_ADDRESS, interface.ipv4_address,
                 'Error: ipv4 address value mismatch after unconfig')
    assert_equal(DEFAULT_IF_IP_NETMASK_LEN,
                 interface.ipv4_netmask_length,
                 'Error: ipv4 netmask length default get value mismatch')

    interface.switchport_mode = :access
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_ipv4_address_getter_with_preconfig
    address = '8.7.1.1'
    length = 15
    ifname = interfaces[0]
    # preconfigure
    interface_ipv4_config(ifname, address, length)
    # create interface
    interface = create_interface(ifname)
    # getter
    assert_equal(address, interface.ipv4_address,
                 'Error: ipv4 address get value mismatch')
    assert_equal(length, interface.ipv4_netmask_length,
                 'Error: ipv4 netmask length get value mismatch')
    # unconfigure ipaddress
    interface_ipv4_config(ifname, address, length, false)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_ipv4_address_getter_with_preconfig_secondary
    address = '8.7.1.1'
    length = 15
    sec_address = '1.1.2.5'
    sec_length = 10
    ifname = interfaces[0]
    # preconfigure primary and secondary
    interface_ipv4_config(ifname, address, length)
    interface_ipv4_config(ifname, sec_address, sec_length, true, true)

    # create interface
    interface = create_interface(ifname)
    # getter
    assert_equal(address, interface.ipv4_address,
                 'Error: ipv4 address get value mismatch')
    assert_equal(length, interface.ipv4_netmask_length,
                 'Error: ipv4 netmask length get value mismatch')
    # unconfigure ipaddress includign secondary
    interface_ipv4_config(ifname, address, length, false, false)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_ipv4_proxy_arp
    interface = create_interface
    interface.switchport_mode = :disabled

    # set with value true
    interface.ipv4_proxy_arp = true
    pattern = (/^\s+ip proxy-arp/)
    line = get_interface_match_line(interface.name, pattern)
    refute_nil(line, 'Error: ip proxy-arp enable missing in CLI')
    assert(interface.ipv4_proxy_arp,
           "Error: ip proxy-arp get value 'true' mismatch")

    # set with value false
    interface.ipv4_proxy_arp = false
    line = get_interface_match_line(interface.name, pattern)
    assert_nil(line, 'Error: ip proxy-arp disable missing in CLI')
    refute(interface.ipv4_proxy_arp,
           "Error: ip proxy-arp get value 'false' mismatch")

    # get default
    assert_equal(DEFAULT_IF_IP_PROXY_ARP,
                 interface.default_ipv4_proxy_arp,
                 'Error: ip proxy arp get default value mismatch')

    # get default and set
    interface.ipv4_proxy_arp = interface.default_ipv4_proxy_arp
    line = get_interface_match_line(interface.name, pattern)
    assert_nil(line, 'Error: default ip proxy-arp set failed')
    assert_equal(DEFAULT_IF_IP_PROXY_ARP,
                 interface.ipv4_proxy_arp,
                 'Error: ip proxy-arp default get value mismatch')

    interface.switchport_mode = :access
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_ipv4_redirects
    interface = create_interface
    interface.switchport_mode = :disabled

    # set with value false
    interface.ipv4_redirects = false
    pattern = (/^\s+no ip redirects/)
    line = get_interface_match_line(interface.name, pattern)
    refute_nil(line, 'Error: ip redirects disable missing in CLI')
    refute(interface.ipv4_redirects,
           "Error: ip redirects get value 'false' mismatch")

    # set with value true
    interface.ipv4_redirects = true
    line = get_interface_match_line(interface.name, pattern)
    assert_nil(line, 'Error: ip redirects enable missing in CLI')
    assert(interface.ipv4_redirects,
           "Error: ip redirects get value 'true' mismatch")

    # get default
    assert_equal(DEFAULT_IF_IP_REDIRECTS,
                 interface.default_ipv4_redirects,
                 'Error: ip redirects get default value mismatch')

    # get default and set
    interface.ipv4_redirects = interface.default_ipv4_redirects
    line = get_interface_match_line(interface.name, pattern)
    assert_nil(line, 'Error: default ip redirects set failed')
    assert_equal(DEFAULT_IF_IP_REDIRECTS, interface.ipv4_redirects,
                 'Error: ip redirects default get value mismatch')

    interface.switchport_mode = :access
    interface_ethernet_default(interfaces_id[0])
  end

  # NOTE - Changes to this method may require new validation methods
  #        to be created or existing ones to be modified.
  def test_interface_ipv4_all_interfaces
    inttype_h = {}
    inttype_h[interfaces[0]] = {
      address_len:         '8.7.1.1/15',
      proxy_arp:           true,
      redirects:           false,
      description:         'This is a test',
      description_new:     'Testing Testing',
      default_description: DEFAULT_IF_DESCRIPTION,
      shutdown:            false,
      change_shutdown:     true,
      default_shutdown:    false,
      switchport:          :disabled,
      default_switchport:  :disabled,
      access_vlan:         DEFAULT_IF_ACCESS_VLAN,
      default_access_vlan: DEFAULT_IF_ACCESS_VLAN,
      vrf_new:             'test2',
      default_vrf:         DEFAULT_IF_VRF,
    }
    inttype_h['Vlan45'] = {
      address_len:         '9.7.1.1/15',
      proxy_arp:           true,
      redirects:           false,
      description:         'Company A',
      description_new:     'Mini Me',
      default_description: DEFAULT_IF_DESCRIPTION,
      shutdown:            true,
      change_shutdown:     false,
      default_shutdown:    true,
      switchport:          :disabled,
      default_switchport:  :disabled,
      access_vlan:         DEFAULT_IF_ACCESS_VLAN,
      default_access_vlan: DEFAULT_IF_ACCESS_VLAN,
      vrf_new:             'test2',
      default_vrf:         DEFAULT_IF_VRF,
    }
    inttype_h['port-channel48'] = {
      address_len:         '10.7.1.1/15',
      proxy_arp:           false,
      redirects:           false,
      description:         'Company B',
      description_new:     'Dr. Bond',
      default_description: DEFAULT_IF_DESCRIPTION,
      shutdown:            false,
      change_shutdown:     true,
      default_shutdown:    false,
      switchport:          :disabled,
      default_switchport:  :disabled,
      access_vlan:         DEFAULT_IF_ACCESS_VLAN,
      default_access_vlan: DEFAULT_IF_ACCESS_VLAN,
      vrf_new:             'test2',
      default_vrf:         DEFAULT_IF_VRF,
    }
    inttype_h['loopback0'] = {
      address_len:         '11.7.1.1/15',
      redirects:           false, # (not supported on loopback)
      description:         '233KLDK',
      description_new:     'Back to the Future',
      default_description: DEFAULT_IF_DESCRIPTION,
      shutdown:            false,
      change_shutdown:     true,
      default_shutdown:    false,
      switchport:          :disabled,
      default_switchport:  :disabled,
      access_vlan:         DEFAULT_IF_ACCESS_VLAN,
      default_access_vlan: DEFAULT_IF_ACCESS_VLAN,
      vrf_new:             'test2',
      default_vrf:         DEFAULT_IF_VRF,
    }
    # Skipping mgmt0 interface since that interface is our 'path' to
    # master should revisit this later

    # Set system defaults to "factory" values prior to initial test.
    system_default_switchport_shutdown_set(
      SWITCHPORT_SHUTDOWN_HASH['shutdown_ethernet_noswitchport_shutdown'])

    # pre-configure
    inttype_h.each do |k, v|
      # puts "TEST: pre-config hash key : #{k}"
      unless (/^Vlan\d./).match(k.to_s).nil?
        @device.cmd('configure terminal')
        @device.cmd('feature interface-vlan')
        @device.cmd('end')
        node.cache_flush
      end

      # puts "TEST: pre-config k: v '#{k} : #{v}'"
      @device.cmd('configure terminal')
      @device.cmd("interface #{k}")
      if !(/^Ethernet\d.\d/).match(k.to_s).nil? ||
         !(/^port-channel\d/).match(k.to_s).nil?
        @device.cmd('no switchport')
      end
      # puts "k: #{k}, k1: #{k1}, address #{v1[:address_len]}"
      @device.cmd("ip address #{v[:address_len]}") unless v[:address_len].nil?
      @device.cmd('ip proxy-arp') if !v[:proxy_arp].nil? && v[:proxy_arp] == true
      @device.cmd('ip redirects') if !v[:redirects].nil? && v[:redirects] == true
      @device.cmd("description #{v[:description]}") unless v[:description].nil?
      @device.cmd('exit')
      @device.cmd('end')

      # Create an Interface instance and associate it
      v[:interface] = Interface.new(k, false)
    end
    # Flush the cache since we've modified the device
    node.cache_flush

    # Validate the collection
    validate_interfaces_not_empty
    validate_get_switchport(inttype_h)
    validate_description(inttype_h)
    validate_get_access_vlan(inttype_h)
    validate_ipv4_address(inttype_h)
    validate_ipv4_proxy_arp(inttype_h)
    validate_ipv4_redirects(inttype_h)
    validate_interface_shutdown(inttype_h)
    validate_vrf(inttype_h)

    # Cleanup the preload configuration
    @device.cmd('configure terminal')
    inttype_h.each_key do |k|
      if !(/^Ethernet\d.\d/).match(k.to_s).nil?
        @device.cmd("default interface #{k}")
      else
        @device.cmd("no interface #{k}")
      end
    end
    @device.cmd('no feature interface-vlan')
    @device.cmd('exit')
    @device.cmd('end')
    node.cache_flush
  end

  def test_interface_vrf_default
    @device.cmd('conf t ; interface loopback1 ; vrf member foo')
    node.cache_flush
    interface = Interface.new('loopback1')
    interface.vrf = interface.default_vrf
    assert_equal(DEFAULT_IF_VRF, interface.vrf)
  end

  def test_interface_vrf_empty
    @device.cmd('conf t ; interface loopback1 ; vrf member foo')
    node.cache_flush
    interface = Interface.new('loopback1')
    interface.vrf = DEFAULT_IF_VRF
    assert_equal(DEFAULT_IF_VRF, interface.vrf)
  end

  def test_interface_vrf_invalid_type
    interface = Interface.new('loopback1')
    assert_raises(TypeError) { interface.vrf = 1 }
  end

  def test_interface_vrf_exceeds_max_length
    interface = Interface.new('loopback1')
    long_string = 'a' * (IF_VRF_MAX_LENGTH + 1)
    assert_raises(RuntimeError) { interface.vrf = long_string }
  end

  def test_interface_vrf_override
    interface = Interface.new('loopback1')
    vrf1 = 'test1'
    vrf2 = 'test2'
    interface.vrf = vrf1
    interface.vrf = vrf2
    assert_equal(vrf2, interface.vrf)
    interface.destroy
  end

  def test_interface_vrf_valid
    interface = Interface.new('loopback1')
    vrf = 'test'
    interface.vrf = vrf
    assert_equal(vrf, interface.vrf)
    interface.destroy
  end
end
