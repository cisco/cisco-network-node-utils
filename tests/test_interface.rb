# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/acl'
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/interface_channel_group'
require_relative '../lib/cisco_node_utils/cisco_cmn_utils'
require_relative '../lib/cisco_node_utils/overlay_global'

include Cisco

# TestInterface - Minitest for general functionality of the Interface class.
class TestInterface < CiscoTestCase
  DEFAULT_IF_ACCESS_VLAN = 1
  DEFAULT_IF_DESCRIPTION = ''
  DEFAULT_IF_IP_ADDRESS = nil
  DEFAULT_IF_IP_NETMASK_LEN = nil
  DEFAULT_IF_IP_PROXY_ARP = false
  DEFAULT_IF_IP_REDIRECTS = true
  DEFAULT_IF_VRF = ''
  IF_VRF_MAX_LENGTH = 32

  def setup
    super
    if platform == :nexus
      @port_channel = 'port-channel'
      # rubocop:disable Style/AlignHash
      @switchport_shutdown_hash = {
        'shutdown_ethernet_switchport_shutdown'     =>
          ['system default switchport',
           'system default switchport shutdown'],
        'shutdown_ethernet_switchport_noshutdown'   =>
          ['system default switchport',
           'no system default switchport shutdown'],
        'shutdown_ethernet_noswitchport_shutdown'   =>
          ['no system default switchport',
           'system default switchport shutdown'],
        'shutdown_ethernet_noswitchport_noshutdown' =>
          ['no system default switchport',
           'no system default switchport shutdown'],
      }
      # rubocop:enable Style/AlignHash
    elsif platform == :ios_xr
      @port_channel = 'Bundle-Ether'
      @switchport_shutdown_hash = {
        # Not really applicable to XR
        'shutdown_ethernet_noswitchport_shutdown' => []
      }
    end
  end

  def teardown
    interface_ethernet_default(interfaces[0])
    super
  end

  def ipv4
    if platform == :nexus
      'ip'
    elsif platform == :ios_xr
      'ipv4'
    end
  end

  def ipv4_address_pattern(address, length, secondary=false)
    if platform == :nexus
      if secondary
        %r{^\s+ip address #{address}/#{length} secondary$}
      else
        %r{^\s+ip address #{address}/#{length}$}
      end
    elsif platform == :ios_xr
      mask = Utils.length_to_bitmask(length)
      if secondary
        /^\s+ipv4 address #{address} #{mask} secondary$/
      else
        /^\s+ipv4 address #{address} #{mask}$/
      end
    end
  end

  def interface_ipv4_config(ifname, address, length,
                            do_config=true, secip=false)
    if do_config
      config_no_warn("interface #{ifname}",
                     'no switchport') if platform == :nexus
      if !secip
        config("interface #{ifname}",
               "#{ipv4} address #{address}/#{length}")
      else
        config("interface #{ifname}",
               "#{ipv4} address #{address}/#{length} secondary")
      end
    else
      config("interface #{ifname}",
             "no #{ipv4} address", # This will remove both primary and secondary
            )
      config("interface #{ifname}",
             'switchport') if platform == :nexus
    end
  end

  def show_cmd(name)
    if platform == :nexus
      all = (name =~ /port-channel\d/ && node.product_id =~ /N7/) ? '' : 'all'
      "show run interface #{name} #{all} | no-more"
    else
      "show run interface #{name}"
    end
  end

  def interface_count
    if platform == :nexus
      cmd = 'show run interface all | inc interface | no-more'
    elsif platform == :ios_xr
      cmd = 'show run interface | inc interface'
    end
    output = @device.cmd(cmd)
    # Next line needs to be done because sh run interface all also shows
    # ospf interface related config
    arr = output.split("\n").select { |str| str.start_with?('interface') }
    refute_empty(arr, "Found no matching lines in:\n#{output}")
    refute_equal(1, arr.count, "Found only one interface in:\n#{output}")
    arr.count
  end

  # Helper to check for misc speed change disallowed error messages.
  def speed_change_disallowed(message)
    patterns = ['port doesn t support this speed',
                'Changing interface speed is not permitted',
                'requested config change not allowed',
                /does not match the (transceiver speed|port capability)/]
    skip('Skip test: Interface type does not allow config change') if
         message[Regexp.union(patterns)]
    flunk(message)
  end

  def create_interface(ifname=interfaces[0])
    @default_show_command = show_cmd(ifname)
    Interface.new(ifname)
  end

  def interface_ethernet_default(ethernet_intf)
    config("default interface #{ethernet_intf}")
  end

  def interface_supports_property?(intf, message)
    patterns = ['requested config change not allowed',
                '% Invalid command']
    skip("Interface '#{intf}' does not support property") if
      message[Regexp.union(patterns)]
    flunk(message)
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
    return state if platform == :ios_xr
    s = @device.cmd("sh run all | in \"system default switchport\"")

    s.split("\n")[1..-2].each do |line|
      state << line unless line.include?('fabricpath')
    end
    state
  end

  def validate_interface_shutdown(inttype_h)
    state = system_default_switchport_shutdown

    # Validate the collection
    inttype_h.each do |k, v|
      interface = v[:interface]

      @switchport_shutdown_hash.each do |lookup_string, config_array|
        # puts "lookup_string: #{lookup_string}"

        # Configure the system default shwitchport and shutdown settings
        config(*config_array)

        interface.shutdown = false
        refute(interface.shutdown,
               "Error: #{interface.name} shutdown is not false")

        interface.shutdown = true
        assert(interface.shutdown,
               "Error: #{interface.name} shutdown is not true")

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
    config(*state)
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
                   "Error: #{interface.name}, switchport mode, default, " \
                   'not correct')
    end
  rescue Cisco::CliError => e
    skip('NX-OS defect: system default switchport nvgens twice') if
      e.message[/Expected zero.one value/]
    flunk(e.message)
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
                   "Error: [#{interface.name}] Default description " \
                   'is not configured')
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

      pattern = ipv4_address_pattern(address, length)
      assert_show_match(command: show_cmd(interface.name),
                        pattern: pattern)
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
      refute_show_match(command: show_cmd(interface.name),
                        pattern: pattern,
                        msg:     "ipv4 address still present in CLI for #{k}")
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
      next if k == 'loopback0'

      interface = v[:interface]
      cmd = show_cmd(interface.name)

      # puts "value - #{v[:proxy_arp]}"
      if platform == :nexus
        pattern = /^\s+ip proxy-arp/
      elsif platform == :ios_xr
        pattern = /^\s+proxy-arp/
      end
      if v[:proxy_arp]
        assert_show_match(command: cmd, pattern: pattern)
      else
        refute_show_match(command: cmd, pattern: pattern)
      end
      assert_equal(v[:proxy_arp], interface.ipv4_proxy_arp,
                   "Error: ip proxy-arp get value 'true' mismatch")

      # puts "value reverse- #{!v[:proxy_arp]}"
      interface.ipv4_proxy_arp = !v[:proxy_arp]
      if v[:proxy_arp]
        refute_show_match(command: cmd, pattern: pattern)
      else
        assert_show_match(command: cmd, pattern: pattern)
      end
      assert_equal(!v[:proxy_arp], interface.ipv4_proxy_arp,
                   "Error: ip proxy-arp get value 'false' mismatch")

      # Get default
      assert_equal(DEFAULT_IF_IP_PROXY_ARP,
                   interface.default_ipv4_proxy_arp,
                   'Error: ip proxy arp get default value mismatch')

      # Get default and set
      interface.ipv4_proxy_arp = interface.default_ipv4_proxy_arp
      refute_show_match(command: cmd, pattern: pattern,
                          msg: 'Error: default ip proxy-arp set failed')
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

      if ref.setter?
        cmd = show_cmd(interface.name)
        interface.ipv4_redirects = true
        assert(interface.ipv4_redirects, "Couldn't set redirects to true")
        refute_show_match(command: cmd, pattern: /^\s+no #{ipv4} redirects/)

        interface.ipv4_redirects = false
        refute(interface.ipv4_redirects, "Couldn't set redirects to false")
        refute_show_match(command: cmd, pattern: /^#{ipv4} redirects/)
      else
        # Getter should return same value as default if setter isn't supported
        assert_equal(interface.ipv4_redirects, interface.default_ipv4_redirects,
                     'ipv4 redirects default incorrect')

        # Make sure setter fails
        assert_raises(Cisco::UnsupportedError) do
          interface.ipv4_redirects = true
        end
        assert_raises(Cisco::UnsupportedError) do
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
                   "Error: [#{interface.name}] vrf config found. " \
                   'Should be default vrf')
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

  def test_interface_description_valid
    interface = Interface.new(interfaces[0])
    description = 'This is a test description ! '
    interface.description = description
    assert_equal(description.rstrip, interface.description)
    interface_ethernet_default(interfaces[0])
  end

  def test_encapsulation_dot1q
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled if platform == :nexus
    subif = Interface.new(interfaces[0] + '.1')
    assert_raises(Cisco::CliError) { subif.encapsulation_dot1q = 'hello' }
    subif.encapsulation_dot1q = 20
    assert_equal(20, subif.encapsulation_dot1q)
    subif.encapsulation_dot1q = 25
    assert_equal(25, subif.encapsulation_dot1q)
    subif.destroy
    interface_ethernet_default(interfaces[0])
  end

  def test_interface_mtu_change
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    interface.mtu = 1520
    assert_equal(1520, interface.mtu)
    interface.mtu = 1580
    assert_equal(1580, interface.mtu)
    interface.mtu = interface.default_mtu
    assert_equal(interface.default_mtu, interface.mtu)
    interface_ethernet_default(interfaces[0])
  end

  def test_interface_mtu_invalid
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    assert_raises(Cisco::CliError) { interface.mtu = 'hello' }
  end

  def test_interface_mtu_valid
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    interface.mtu = 1550
    assert_equal(1550, interface.mtu)
    interface.mtu = interface.default_mtu
    assert_equal(interface.default_mtu, interface.mtu)
    interface_ethernet_default(interfaces[0])
  end

  def test_mtu_invalid_loopback
    # Loopback interfaces don't permit MTU configuration
    interface = Interface.new('loopback100')
    assert_nil(interface.mtu)
    assert_nil(interface.default_mtu)
    assert_raises(Cisco::UnsupportedError) { interface.mtu = 1550 }
    interface.destroy
  end

  def test_speed
    interface = Interface.new(interfaces[0])
    if platform == :ios_xr
      assert_nil(interface.speed)
      assert_nil(interface.default_speed)
      assert_raises(Cisco::UnsupportedError) { interface.speed = 1000 }
    else
      assert_raises(RuntimeError, Cisco::CliError) { interface.speed = 'hello' }
      begin
        interface.speed = 1000
        assert_equal('1000', interface.speed)
        interface.speed = 100
        assert_equal('100', interface.speed)
      rescue Cisco::CliError => e
        speed_change_disallowed(e.message)
      end
    end
    interface_ethernet_default(interfaces[0])
  end

  def test_duplex
    interface = Interface.new(interfaces[0])
    if platform == :ios_xr
      assert_nil(interface.duplex)
      assert_nil(interface.default_duplex)
      assert_raises(Cisco::UnsupportedError) { interface.duplex = 'full' }
    else
      assert_raises(RuntimeError, Cisco::CliError) do
        interface.duplex = 'hello'
      end
      interface.speed = 1000
      begin
        interface.duplex = 'full'
        assert_equal('full', interface.duplex)
        interface.duplex = 'auto'
        assert_equal('auto', interface.duplex)
      rescue Cisco::CliError => e
        speed_change_disallowed(e.message)
      end
    end
    interface_ethernet_default(interfaces[0])
  end

  def test_interface_shutdown_valid
    interface = Interface.new(interfaces[0])
    interface.shutdown = true
    assert(interface.shutdown, 'Error: shutdown state is not true')

    interface.shutdown = false
    refute(interface.shutdown, 'Error: shutdown state is not false')
    interface_ethernet_default(interfaces[0])
  end

  def test_svi_prop_nil_when_ethernet
    intf = Interface.new(interfaces[0])
    assert_nil(intf.svi_autostate,
               'Error: svi_autostate should be nil when interface is ethernet')
    assert_nil(intf.svi_management,
               'Error: svi_management should be nil when interface is ethernet')
  end

  #   def test_interface_get_prefix_list_when_switchport
  #     interface = Interface.new(interfaces[0])
  #     interface.switchport_mode = :access
  #     addresses = interface.prefixes
  #     assert_empty(addresses)
  #     interface_ethernet_default(interfaces[0])
  #   end
  #
  #   def test_interface_get_prefix_list_with_ipv4_address_assignment
  #     interface = Interface.new(interfaces[0])
  #     interface.switchport_mode = :access
  #     interface.switchport_mode = :disabled if platform == :nexus
  #     config("interface #{interfaces[0]}",
  #            'ip address 192.168.1.100 255.255.255.0')
  #     prefixes = interface.prefixes
  #     assert_equal(1, prefixes.size)
  #     assert(prefixes.has_key?("192.168.1.100"))
  #     interface.switchport_mode = :access
  #     prefixes = nil
  #     interface_ethernet_default(interfaces[0])
  #   end
  #
  #   def test_interface_get_prefix_list_with_ipv6_address_assignment
  #     interface = Interface.new(interfaces[0] )
  #     interface.switchport_mode = :access
  #     interface.switchport_mode = :disabled if platform == :nexus
  #     config("interface #{interfaces[0]}",
  #            'ipv6 address fd56:31f7:e4ad:5585::1/64")
  #     prefixes = interface.prefixes
  #     assert_equal(2, prefixes.size)
  #     assert(prefixes.has_key?("fd56:31f7:e4ad:5585::1"))
  #     interface.switchport_mode = :access
  #     prefixes = nil
  #     interface_ethernet_default(interfaces[0])
  #   end
  #
  #   def test_interface_prefix_list_with_both_ip4_and_ipv6_address_assignments
  #     interface = Interface.new(interfaces[0])
  #     interface.switchport_mode = :access
  #     interface.switchport_mode = :disabled if platform == :nexus
  #     config("interface #{interfaces[0]}",
  #            'ip address 192.168.1.100 255.255.255.0',
  #            'ipv6 address fd56:31f7:e4ad:5585::1/64')
  #     prefixes = interface.prefixes
  #     assert_equal(3, prefixes.size)
  #     assert(prefixes.has_key?("192.168.1.100"))
  #     assert(prefixes.has_key?("fd56:31f7:e4ad:5585::1"))
  #     interface.switchport_mode = :access
  #     prefixes = nil
  #     interface_ethernet_default(interfaces[0])
  #   end

  def negotiate_auto_helper(interface, default, cmd_ref)
    inf_name = interface.name

    # Test default
    assert_equal(default, interface.default_negotiate_auto,
                 "Error: #{inf_name} negotiate auto default value mismatch")

    interface.negotiate_auto = default
    # Delay as this change is sometimes too quick for some interfaces
    sleep 1 unless default == interface.negotiate_auto
    node.cache_flush
    assert_equal(default, interface.negotiate_auto,
                 "Error: #{inf_name} negotiate auto value " \
                 'should be same as default')

    unless cmd_ref.setter?
      # check the set for unsupported platforms
      assert_raises(RuntimeError) do
        interface.negotiate_auto = true
      end
      return
    end

    interface.negotiate_auto = default
    assert_equal(default, interface.negotiate_auto,
                 "Error: #{inf_name} negotiate auto value not #{default}")

    if default
      pattern = /^\s+negotiate auto/
    else
      pattern = /^\s+no negotiate auto/
    end
    assert_show_match(pattern: pattern)

    non_default = !default

    # Some 'supported' platforms let us set the negotiate value to its
    # default but not actually change it.
    begin
      interface.negotiate_auto = non_default
    rescue RuntimeError
      assert_equal(default, interface.negotiate_auto,
                   "Error: #{inf_name} negotiate auto value not #{default}")
      return
    end

    # Delay as this change is sometimes too quick for some interfaces
    sleep 1 unless non_default == interface.negotiate_auto
    node.cache_flush

    assert_equal(non_default, interface.negotiate_auto,
                 "Error: #{inf_name} negotiate auto value not #{non_default}")

    if non_default
      pattern = /^\s+negotiate auto/
    else
      pattern = /^\s+no negotiate auto/
    end
    assert_show_match(pattern: pattern)

    # Clean up after ourselves
    interface.negotiate_auto = default
    assert_equal(default, interface.negotiate_auto,
                 "Error: #{inf_name} negotiate auto value not #{default}")

    if default
      pattern = /^\s+negotiate auto/
    else
      pattern = /^\s+no negotiate auto/
    end
    assert_show_match(pattern: pattern)
  end

  def test_negotiate_auto_portchannel
    ref = cmd_ref.lookup('interface',
                         'negotiate_auto_portchannel')
    assert(ref, 'Error, reference not found')

    # Create interface member of this group (required for XR)
    interface_ethernet_default(interfaces[0])
    member = InterfaceChannelGroup.new(interfaces[0])
    begin
      member.channel_group = 10
    rescue Cisco::UnsupportedError
      # Some XR platform/version combinations don't support port-channel intfs
      skip('bundle id config not supported on this node') if platform == :ios_xr
      raise
    end

    inf_name = "#{@port_channel}10"
    interface = Interface.new(inf_name)
    if platform == :ios_xr
      assert_nil(interface.negotiate_auto)
      assert_nil(interface.default_negotiate_auto)
      assert_raises(Cisco::UnsupportedError) do
        interface.negotiate_auto = false
      end
    else
      default = ref.default_value
      @default_show_command = show_cmd(inf_name)

      # Test with switchport
      negotiate_auto_helper(interface, default, ref)

      # Test with no switchport
      config("interface #{@port_channel} 10", 'no switchport')
      negotiate_auto_helper(interface, default, ref)
    end

    # Cleanup
    config("no interface #{@port_channel} 10")
    member.channel_group = false # rubocop:disable Lint/UselessSetterCall
  end

  def test_negotiate_auto_ethernet
    ref = cmd_ref.lookup('interface',
                         'negotiate_auto_ethernet')
    assert(ref, 'Error, reference not found')

    # Cleanup
    interface_ethernet_default(interfaces[0])

    # Some platforms does not support negotiate auto
    # if so then we abort the test.

    inf_name = interfaces[0]
    interface = Interface.new(inf_name)

    if platform == :ios_xr
      assert_nil(interface.negotiate_auto)
      assert_nil(interface.default_negotiate_auto)
      assert_raises(Cisco::UnsupportedError) do
        interface.negotiate_auto = false
      end
      return
    end

    # Some platforms/interfaces/versions do not support negotiation changes
    begin
      interface.negotiate_auto = false
    rescue Cisco::CliError => e
      skip('Skip test: Interface type does not allow config change') if
        e.message[/requested config change not allowed/]
      flunk(e.message) unless
        e.message[/cannot turn off auto-negotiate with auto-negotiate speeds/]
    end

    default = ref.default_value
    @default_show_command = show_cmd(inf_name)

    # Test with switchport
    negotiate_auto_helper(interface, default, ref)

    # Test with no switchport
    config_no_warn("interface #{interfaces[0]}", 'no switchport')
    negotiate_auto_helper(interface, default, ref)

    # Cleanup
    interface_ethernet_default(interfaces[0])
  end

  def test_negotiate_auto_loopback
    ref = cmd_ref.lookup('interface',
                         'negotiate_auto_other_interfaces')
    assert(ref, 'Error, reference not found')

    inf_name = 'loopback2'
    config('interface loopback 2')
    interface = Interface.new(inf_name)

    assert_equal(ref.default_value, interface.negotiate_auto,
                 "Error: #{inf_name} negotiate auto value mismatch")

    assert_raises(Cisco::UnsupportedError) do
      interface.negotiate_auto = true
    end
    assert_raises(Cisco::UnsupportedError) do
      interface.negotiate_auto = false
    end

    # Cleanup
    config('no interface loopback 2')
  end

  def test_interfaces_not_empty
    refute_empty(Interface.interfaces, 'Error: interfaces collection empty')
  end

  def test_interface_ipv4_addr_mask_set_address_invalid
    interface = create_interface
    interface.switchport_mode = :disabled if platform == :nexus
    assert_raises(Cisco::CliError) do
      interface.ipv4_addr_mask_set('', 14)
    end
    interface_ethernet_default(interfaces[0])
  end

  def test_interface_ipv4_addr_mask_set_netmask_invalid
    interface = create_interface
    interface.switchport_mode = :disabled if platform == :nexus
    assert_raises(Cisco::CliError) do
      interface.ipv4_addr_mask_set('8.1.1.2', DEFAULT_IF_IP_NETMASK_LEN)
    end
    interface_ethernet_default(interfaces[0])
  end

  def test_ipv4_acl
    # Sample cli:
    #
    #   interface Ethernet1/1
    #     ip access-group v4acl1 in
    #     ip access-group v4acl2 out
    #

    # create acls first
    %w(v4acl1 v4acl2 v4acl3 v4acl4).each do |acl_name|
      if platform == :nexus
        Acl.new('ipv4', acl_name)
      else
        # TODO: Acl is not yet supported on XR
        config("ipv4 access-list #{acl_name} 1 permit any")
      end
    end
    interface_ethernet_default(interfaces[0])
    intf = Interface.new(interfaces[0])

    intf.ipv4_acl_in = 'v4acl1'
    assert_equal('v4acl1', intf.ipv4_acl_in)
    intf.ipv4_acl_out = 'v4acl2'
    assert_equal('v4acl2', intf.ipv4_acl_out)

    intf.ipv4_acl_in = 'v4acl3'
    assert_equal('v4acl3', intf.ipv4_acl_in)
    intf.ipv4_acl_out = 'v4acl4'
    assert_equal('v4acl4', intf.ipv4_acl_out)

    intf.ipv4_acl_in = intf.default_ipv4_acl_in
    assert_equal('', intf.ipv4_acl_in)
    intf.ipv4_acl_out = intf.default_ipv4_acl_out
    assert_equal('', intf.ipv4_acl_out)

    # delete acls
    %w(v4acl1 v4acl2 v4acl3 v4acl4).each do |acl_name|
      config("no #{ipv4} access-list #{acl_name}")
    end
  end

  def test_ipv6_acl
    # Sample cli:
    #
    #   interface Ethernet1/1
    #     ipv6 traffic-filter v6acl1 in
    #     ipv6 traffic-filter v6acl2 out
    #
    interface_ethernet_default(interfaces[0])
    intf = Interface.new(interfaces[0])

    # create acls first
    %w(v6acl1 v6acl2 v6acl3 v6acl4).each do |acl_name|
      if platform == :nexus
        Acl.new('ipv6', acl_name)
      else
        # TODO: Acl is not yet supported on XR
        config("ipv6 access-list #{acl_name} 1 permit any any")
      end
    end

    intf.ipv6_acl_in = 'v6acl1'
    assert_equal('v6acl1', intf.ipv6_acl_in)
    intf.ipv6_acl_out = 'v6acl2'
    assert_equal('v6acl2', intf.ipv6_acl_out)

    intf.ipv6_acl_in = 'v6acl3'
    assert_equal('v6acl3', intf.ipv6_acl_in)
    intf.ipv6_acl_out = 'v6acl4'
    assert_equal('v6acl4', intf.ipv6_acl_out)

    intf.ipv6_acl_in = intf.default_ipv6_acl_in
    assert_equal('', intf.ipv6_acl_in)
    intf.ipv6_acl_out = intf.default_ipv6_acl_out
    assert_equal('', intf.ipv6_acl_out)

    # delete acls
    %w(v6acl1 v6acl2 v6acl3 v6acl4).each do |acl_name|
      config('no ipv6 access-list ' + acl_name)
    end
  end

  def test_interface_ipv4_address
    interface = create_interface
    interface.switchport_mode = :disabled if platform == :nexus
    address = '8.7.1.1'
    sec_addr = '10.5.5.1'
    secondary = true
    length = 15

    # Primary: setter, getter
    interface.ipv4_addr_mask_set(address, length)
    pattern = ipv4_address_pattern(address, length)
    assert_show_match(pattern: pattern,
                      msg:     'Error: ipv4 address missing in CLI')
    assert_equal(address, interface.ipv4_address,
                 'Error: ipv4 address get value mismatch')
    assert_equal(length, interface.ipv4_netmask_length,
                 'Error: ipv4 netmask length get value mismatch')

    # Secondary: setter, getter
    interface.ipv4_addr_mask_set(sec_addr, length, secondary)
    pattern = ipv4_address_pattern(sec_addr, length, secondary)
    assert_show_match(pattern: pattern,
                      msg:     'Error: ipv4 address missing in CLI')
    assert_equal(sec_addr, interface.ipv4_address_secondary,
                 'Error: ipv4 address get value mismatch')
    assert_equal(length, interface.ipv4_netmask_length_secondary,
                 'Error: ipv4 netmask length get value mismatch')

    # get default
    assert_equal(DEFAULT_IF_IP_ADDRESS, interface.default_ipv4_address,
                 'Error: ipv4 address get default value mismatch')

    # get_default_netmask
    assert_equal(DEFAULT_IF_IP_NETMASK_LEN,
                 interface.default_ipv4_netmask_length,
                 'Error: ipv4 netmask length get default value mismatch')

    # unconfigure ipaddress - secondary must be removed first
    interface.ipv4_addr_mask_set(interface.default_ipv4_address, length,
                                 secondary)
    interface.ipv4_addr_mask_set(interface.default_ipv4_address, length)
    # unconfigure should be safely idempotent
    interface.ipv4_addr_mask_set(interface.default_ipv4_address, length,
                                 secondary)
    interface.ipv4_addr_mask_set(interface.default_ipv4_address, length)
    pattern = (/^\s+ip(v4)? address (.*)/)
    refute_show_match(pattern: pattern,
                      msg:     'Error: ipv4 address still present in CLI')
    assert_equal(DEFAULT_IF_IP_ADDRESS, interface.ipv4_address,
                 'Error: ipv4 address value mismatch after unconfig')
    assert_equal(DEFAULT_IF_IP_NETMASK_LEN,
                 interface.ipv4_netmask_length,
                 'Error: ipv4 netmask length default get value mismatch')

    interface_ethernet_default(interfaces[0])
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
    interface_ethernet_default(interfaces[0])
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
    interface_ethernet_default(interfaces[0])
  end

  def test_interface_ipv4_arp_timeout
    unless platform == :ios_xr
      # Setup
      config_no_warn('no interface vlan11')
      int = Interface.new('vlan11')

      # Test default
      assert_equal(int.default_ipv4_arp_timeout, int.ipv4_arp_timeout)
      # Test non-default
      int.ipv4_arp_timeout = 300
      assert_equal(300, int.ipv4_arp_timeout)
      # Set back to default
      int.ipv4_arp_timeout = int.default_ipv4_arp_timeout
      assert_equal(int.default_ipv4_arp_timeout, int.ipv4_arp_timeout)
    end
    # Attempt to configure on a non-vlan interface
    nonvlanint = create_interface
    assert_raises(RuntimeError) { nonvlanint.ipv4_arp_timeout = 300 }
  end

  def test_interface_ipv4_forwarding
    intf = interfaces[0]
    interface_ethernet_default(interfaces[0])
    i = Interface.new(intf)

    if platform == :ios_xr
      assert_nil(i.default_ipv4_forwarding)
      assert_nil(i.ipv4_forwarding)
      assert_raises(Cisco::UnsupportedError) { i.ipv4_forwarding = false }
      return
    end

    assert_equal(i.default_ipv4_forwarding, i.ipv4_forwarding)
    begin
      i.switchport_mode = :disabled
      i.ipv4_forwarding = true
    rescue RuntimeError, CliError => e
      # RuntimeError when switchport_mode fails (some lc's, e.g. N7K-F248XP-25E)
      # CliError when ipv4_forwarding fails
      interface_supports_property?(intf, e.message)
    end
    assert(i.ipv4_forwarding)

    i.ipv4_forwarding = false
    refute(i.ipv4_forwarding)

    i.ipv4_forwarding = true
    assert(i.ipv4_forwarding)
    i.ipv4_forwarding = i.default_ipv4_forwarding
    assert_equal(i.default_ipv4_forwarding, i.ipv4_forwarding)
  end

  def test_interface_fabric_forwarding_anycast_gateway
    unless platform == :ios_xr
      # Setup
      config_no_warn('no interface vlan11')
      int = Interface.new('vlan11')
      foo = OverlayGlobal.new
      foo.anycast_gateway_mac = '1223.3445.5668'

      # 1. Testing default for newly created vlan
      assert_equal(int.default_fabric_forwarding_anycast_gateway,
                   int.fabric_forwarding_anycast_gateway)

      # 2. Testing non-default:true
      int.fabric_forwarding_anycast_gateway = true
      assert(int.fabric_forwarding_anycast_gateway)

      # 3. Setting back to false
      int.fabric_forwarding_anycast_gateway = false
      refute(int.fabric_forwarding_anycast_gateway)
    end

    # 4. Attempt to configure on a non-vlan interface
    nonvlanint = create_interface
    assert_raises(RuntimeError) do
      nonvlanint.fabric_forwarding_anycast_gateway = true
    end

    unless platform == :ios_xr # rubocop:disable Style/GuardClause
      # 5. Attempt to set 'fabric forwarding anycast gateway' while the
      #    overlay gateway mac is not set.
      int = Interface.new('vlan11')
      foo = OverlayGlobal.new
      foo.anycast_gateway_mac = foo.default_anycast_gateway_mac
      assert_raises(RuntimeError) do
        int.fabric_forwarding_anycast_gateway = true
      end
    end
  end

  def test_interface_ipv4_proxy_arp
    interface = create_interface
    interface.switchport_mode = :disabled if platform == :nexus

    # set with value true
    interface.ipv4_proxy_arp = true
    if platform == :nexus
      pattern = /^\s+ip proxy-arp/
    elsif platform == :ios_xr
      pattern = /^\s+proxy-arp/
    end
    assert_show_match(pattern: pattern,
                      msg:     'Error: ip proxy-arp enable missing in CLI')
    assert(interface.ipv4_proxy_arp,
           "Error: ip proxy-arp get value 'true' mismatch")

    # set with value false
    interface.ipv4_proxy_arp = false
    refute_show_match(pattern: pattern,
                      msg:     'Error: ip proxy-arp disable missing in CLI')
    refute(interface.ipv4_proxy_arp,
           "Error: ip proxy-arp get value 'false' mismatch")

    # get default
    assert_equal(DEFAULT_IF_IP_PROXY_ARP,
                 interface.default_ipv4_proxy_arp,
                 'Error: ip proxy arp get default value mismatch')

    # get default and set
    interface.ipv4_proxy_arp = interface.default_ipv4_proxy_arp
    refute_show_match(pattern: pattern,
                      msg:     'Error: default ip proxy-arp set failed')
    assert_equal(DEFAULT_IF_IP_PROXY_ARP,
                 interface.ipv4_proxy_arp,
                 'Error: ip proxy-arp default get value mismatch')

    interface_ethernet_default(interfaces[0])
  end

  def test_interface_ipv4_redirects
    interface = create_interface
    interface.switchport_mode = :disabled if platform == :nexus

    ref = cmd_ref.lookup('interface', 'ipv4_redirects_other_interfaces')
    assert(ref, 'Error, reference not found')

    # check default value
    assert_equal(interface.default_ipv4_redirects, interface.ipv4_redirects,
                 'Error: ip redirects default get value mismatch')

    # set with value false
    interface.ipv4_redirects = false
    if interface.default_ipv4_redirects == true
      assert_show_match(pattern: /^\s+no #{ipv4} redirects/,
                        msg:     'Error: ip redirects disable missing in CLI')
    end
    refute_show_match(pattern: /^\s+#{ipv4} redirects/)
    refute(interface.ipv4_redirects,
           "Error: ip redirects get value 'false' mismatch")

    # set with value true
    interface.ipv4_redirects = true
    if interface.default_ipv4_redirects == false
      assert_show_match(pattern: /^\s+#{ipv4} redirects/)
    end
    refute_show_match(pattern: /^\s+no #{ipv4} redirects/,
                      msg:     'Error: ip redirects enable missing in CLI')
    assert(interface.ipv4_redirects,
           "Error: ip redirects get value 'true' mismatch")

    # get default and set
    interface.ipv4_redirects = interface.default_ipv4_redirects
    if interface.default_ipv4_redirects
      pat = /^\s+no #{ipv4} redirects/
    else
      pat = /^\s+#{ipv4} redirects/
    end
    refute_show_match(pattern: pat,
                      msg:     'Error: default ip redirects set failed')
    assert_equal(interface.default_ipv4_redirects, interface.ipv4_redirects,
                 'Error: ip redirects default get value mismatch')

    interface_ethernet_default(interfaces[0])
  end

  def config_from_hash(inttype_h)
    inttype_h.each do |k, v|
      # puts "TEST: pre-config hash key : #{k}"
      config('feature interface-vlan') if (/^Vlan\d./).match(k.to_s)

      # puts "TEST: pre-config k: v '#{k} : #{v}'"
      cfg = ["interface #{k}"]
      if !(/^Ethernet\d.\d/).match(k.to_s).nil? ||
         !(/^#{@port_channel}\d/).match(k.to_s).nil?
        cfg << 'no switchport'
      end
      # puts "k: #{k}, k1: #{k1}, address #{v1[:address_len]}"
      cfg << "#{ipv4} address #{v[:address_len]}" unless v[:address_len].nil?
      if platform == :nexus
        cfg << 'ip proxy-arp' if v[:proxy_arp]
      elsif platform == :ios_xr
        cfg << 'proxy-arp' if v[:proxy_arp]
      end
      cfg << '#{ipv4} redirects' if v[:redirects]
      cfg << "description #{v[:description]}" unless v[:description].nil?
      config(*cfg)

      # Create an Interface instance and associate it
      v[:interface] = Interface.new(k, false)
    end
    inttype_h
  end

  def interface_test_data
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
      switchport:          platform == :ios_xr ? nil : :disabled,
      default_switchport:  platform == :ios_xr ? nil : :disabled,
      access_vlan:         DEFAULT_IF_ACCESS_VLAN,
      default_access_vlan: DEFAULT_IF_ACCESS_VLAN,
      vrf_new:             'test2',
      default_vrf:         DEFAULT_IF_VRF,
    }
    unless platform == :ios_xr
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
    end
    inttype_h["#{@port_channel}48"] = {
      address_len:         '10.7.1.1/15',
      proxy_arp:           false,
      redirects:           false,
      description:         'Company B',
      description_new:     'Dr. Bond',
      default_description: DEFAULT_IF_DESCRIPTION,
      shutdown:            false,
      change_shutdown:     true,
      default_shutdown:    false,
      switchport:          platform == :ios_xr ? nil : :disabled,
      default_switchport:  platform == :ios_xr ? nil : :disabled,
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
      switchport:          platform == :ios_xr ? nil : :disabled,
      default_switchport:  platform == :ios_xr ? nil : :disabled,
      access_vlan:         DEFAULT_IF_ACCESS_VLAN,
      default_access_vlan: DEFAULT_IF_ACCESS_VLAN,
      vrf_new:             'test2',
      default_vrf:         DEFAULT_IF_VRF,
    }
    # Skipping mgmt0 interface since that interface is our 'path' to
    # master should revisit this later
    inttype_h
  end

  # NOTE - Changes to this method may require new validation methods
  #        to be created or existing ones to be modified.
  def test_interface_ipv4_all_interfaces
    inttype_h = interface_test_data

    # Set system defaults to "factory" values prior to initial test.
    config(*
      @switchport_shutdown_hash['shutdown_ethernet_noswitchport_shutdown'])

    # pre-configure
    begin
      InterfaceChannelGroup.new(interfaces[1]).channel_group = 48
    rescue Cisco::UnsupportedError
      raise unless platform == :ios_xr
      # Some XR platform/version combos don't support port-channels
      inttype_h.delete("#{@port_channel}48")
    end

    inttype_h = config_from_hash(inttype_h)

    # Steps to cleanup the preload configuration
    cfg = []
    inttype_h.each_key do |k|
      if /ethernet/.match(k)
        # leave interface there, but unconfigure it
        cfg.push(*get_interface_cleanup_config(k))
      else
        # remove interface
        cfg << "no interface #{k}"
      end
    end
    cfg << 'no feature interface-vlan' unless platform == :ios_xr

    begin
      # Validate the collection
      validate_interfaces_not_empty
      validate_get_switchport(inttype_h)
      validate_description(inttype_h)
      validate_get_access_vlan(inttype_h) unless platform == :ios_xr
      validate_ipv4_address(inttype_h)
      validate_ipv4_proxy_arp(inttype_h)
      validate_ipv4_redirects(inttype_h)
      validate_interface_shutdown(inttype_h)
      validate_vrf(inttype_h)
      config(*cfg)
      InterfaceChannelGroup.new(interfaces[1]).channel_group = false
    rescue Minitest::Assertion
      # clean up before failing
      config(*cfg)
      interface_ethernet_default(interfaces[1])
      raise
    end
  end

  def test_interface_vrf_default
    interface = Interface.new('loopback1')
    interface.vrf = interface.default_vrf
    assert_equal(DEFAULT_IF_VRF, interface.vrf)
  end

  def test_interface_vrf_empty
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
    assert_raises(Cisco::CliError) { interface.vrf = long_string }
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

  def test_vrf_change_with_ip_addr
    interface = Interface.new('loopback1')
    address = '192.168.100.1'
    length = 24
    interface_ipv4_config('loopback1', address, length)
    assert_equal(address, interface.ipv4_address)
    assert_equal(length, interface.ipv4_netmask_length)

    vrf1 = 'test1'
    interface.vrf = vrf1
    assert_equal(address, interface.ipv4_address,
                 'IPv4 address wrong after changing from vrf default => test1')
    assert_equal(length, interface.ipv4_netmask_length,
                 'IPv4 mask wrong after changing from vrf default => test1')
    assert_equal(vrf1, interface.vrf)

    vrf2 = 'test2'
    interface.vrf = vrf2
    assert_equal(address, interface.ipv4_address,
                 'IPv4 address wrong after changing from vrf test1 => test2')
    assert_equal(length, interface.ipv4_netmask_length,
                 'IPv4 mask wrong after changing from vrf test1 => test2')
    assert_equal(vrf2, interface.vrf)

    interface.vrf = DEFAULT_IF_VRF
    assert_equal(address, interface.ipv4_address,
                 'IPv4 address wrong after changing from vrf test2 => default')
    assert_equal(length, interface.ipv4_netmask_length,
                 'IPv4 mask wrong after changing from vrf test2 => default')
    assert_equal(DEFAULT_IF_VRF, interface.vrf)
  end

  def test_ipv4_pim_sparse_mode
    config('no feature pim') if platform == :nexus
    i = Interface.new(interfaces[0])
    if platform == :ios_xr
      assert_nil(i.ipv4_pim_sparse_mode)
      assert_nil(i.default_ipv4_pim_sparse_mode)
      assert_raises(Cisco::UnsupportedError) { i.ipv4_pim_sparse_mode = true }
      return
    end
    # Sample cli:
    #
    #   interface Ethernet1/1
    #     ip pim sparse-mode
    #
    i.ipv4_pim_sparse_mode = false
    refute(i.ipv4_pim_sparse_mode)

    i.ipv4_pim_sparse_mode = true
    assert(i.ipv4_pim_sparse_mode)

    i.ipv4_pim_sparse_mode = i.default_ipv4_pim_sparse_mode
    assert_equal(i.default_ipv4_pim_sparse_mode, i.ipv4_pim_sparse_mode)
  end
end
