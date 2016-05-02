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
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/vlan'

include Cisco

# TestInterfaceSwitchport
# Parent class for specific types of switchport tests (below)
class TestInterfaceSwitchport < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars
  attr_reader :interface

  def setup
    super
    @interface = Interface.new(interfaces[0])
    cleanup if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
    super
  end

  def cleanup
    remove_svis
    cleanup_pvlan_intfs
    remove_all_vlans
    config_no_warn('no feature private-vlan', 'no feature vtp')
  end

  def remove_svis
    Interface.interfaces.each do |name, _i|
      next unless name[/vlan/] || name.match(/^vlan1$/)
      config("no interface #{name}")
    end
  end

  def cleanup_pvlan_intfs
    pvlan_intfs = Interface.interfaces(:private_vlan_any)
    pvlan_intfs.keys.each { |name| interface_cleanup(name) }
  end
end

# TestSwitchport - general interface switchport tests.
class TestSwitchport < TestInterfaceSwitchport
  def test_interface_switchport_private_host_mode
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    switchport_modes = [
      :host,
      :promiscuous,
    ]

    switchport_modes.each do |start|
      interface.switchport_mode_private_vlan_host = start
      assert_equal(start, interface.switchport_mode_private_vlan_host,
                   "Err: Switchport mode, #{start}, not as expected")
    end
  end

  def test_interface_switchport_private_trunk_promisc
    if validate_property_excluded?(
      'interface',
      'switchport_mode_private_vlan_trunk_secondary')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_trunk_promiscuous = true
      end
      return
    end
    interface.switchport_mode_private_vlan_trunk_promiscuous = true
    assert(interface.switchport_mode_private_vlan_trunk_promiscuous,
           'Err: Switchport mode, not as expected')
  end

  def test_interface_switchport_private_trunk_secondary
    if validate_property_excluded?(
      'interface',
      'switchport_mode_private_vlan_trunk_secondary')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_trunk_secondary = true
      end
      return
    end
    interface.switchport_mode_private_vlan_trunk_secondary = true
    assert(interface.switchport_mode_private_vlan_trunk_secondary,
           'Err: Switchport mode, not as expected')
  end

  def test_interface_no_switchport_private_host_mode
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    switchport_modes = [
      :host,
      :promiscuous,
    ]

    switchport_modes.each do |start|
      interface.switchport_mode_private_vlan_host = start
      assert_equal(start, interface.switchport_mode_private_vlan_host,
                   "Err: Switchport mode, #{start}, not as expected")
      interface.switchport_mode_private_vlan_host = :disabled
      assert_equal(:disabled, interface.switchport_mode_private_vlan_host,
                   'Error: Switchport mode not disabled')
    end
  end

  def test_interface_no_switchport_private_trunk_mode
    if validate_property_excluded?(
      'interface',
      'switchport_mode_private_vlan_trunk_secondary')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_trunk_secondary = true
      end
      return
    end
    interface.switchport_mode_private_vlan_trunk_secondary = true
    assert(interface.switchport_mode_private_vlan_trunk_secondary,
           'Err: Switchport mode not as expected')
    interface.switchport_mode_private_vlan_trunk_secondary = false
    refute(interface.switchport_mode_private_vlan_trunk_secondary,
           'Err: Switchport mode not disabled')
  end

  def test_interface_switchport_private_host_association
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    v1 = Vlan.new(10)
    v1.private_vlan_type = 'primary'
    v2 = Vlan.new(11)
    v2.private_vlan_type = 'community'
    v1.private_vlan_association = ['11']

    interface.switchport_mode_private_vlan_host = :host
    assert_equal(:host, interface.switchport_mode_private_vlan_host,
                 'Err: Switchport mode not as expected')

    input = %w(10 11)

    interface.switchport_mode_private_vlan_host_association = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_association,
                 'Err: switchport private host_association not configured')
  end

  def test_interface_switchport_pvlan_host_assoc_change
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    v1 = Vlan.new(10)
    v1.private_vlan_type = 'primary'
    v2 = Vlan.new(11)
    v2.private_vlan_type = 'community'
    v1.private_vlan_association = ['11']

    interface.switchport_mode_private_vlan_host = :host
    assert_equal(:host, interface.switchport_mode_private_vlan_host,
                 'Error: Switchport mode not as expected')

    input = %w(10 11)

    interface.switchport_mode_private_vlan_host_association = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_association,
                 'Err: switchport private host_association not configured')

    v3 = Vlan.new(20)
    v3.private_vlan_type = 'primary'

    v4 = Vlan.new(21)
    v4.private_vlan_type = 'community'
    v3.private_vlan_association = ['21']

    input = %w(20 21)
    interface.switchport_mode_private_vlan_host_association = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_association,
                 'Err: switchport private host_association not configured')

    input = []
    interface.switchport_mode_private_vlan_host_association = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_association,
                 'Err: switchport private host_association not configured')
  end

  def test_interface_switchport_no_pvlan_host_assoc
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    v1 = Vlan.new(10)
    v1.private_vlan_type = 'primary'
    v2 = Vlan.new(11)
    v2.private_vlan_type = 'community'
    v1.private_vlan_association = ['11']

    input = %w(10 11)
    interface.switchport_mode_private_vlan_host = :host
    assert_equal(:host, interface.switchport_mode_private_vlan_host,
                 'Err: Switchport mode not as expected')
    interface.switchport_mode_private_vlan_host_association = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_association,
                 'Err: switchport private host_association not configured')
    input = []
    interface.switchport_mode_private_vlan_host_association = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_association,
                 'Err: switchport private host_association not configured')
  end

  def test_interface_switchport_pvlan_host_assoc_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    val = interface.default_switchport_mode_private_vlan_host_association
    assert_equal(val, interface.switchport_mode_private_vlan_host_association,
                 'Err: host association failed')
  end

  def test_interface_switchport_pvlan_host_assoc_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    interface.switchport_mode_private_vlan_host = :host
    assert_equal(:host, interface.switchport_mode_private_vlan_host,
                 'Err: Switchport mode not as expected')

    input = %w(10)
    assert_raises(CliError) do
      interface.switchport_mode_private_vlan_host_association = input
    end

    input = %w(10 ten)
    assert_raises(CliError) do
      interface.switchport_mode_private_vlan_host_association = input
    end

    input = %w(10,12)
    assert_raises(CliError) do
      interface.switchport_mode_private_vlan_host_association = input
    end

    input = %w(10 10)
    assert_raises(RuntimeError,
                  'host association did not raise RuntimeError') do
      interface.switchport_mode_private_vlan_host_association = input
    end
  end

  def test_interface_switchport_pvlan_host_primisc_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    val = interface.default_switchport_mode_private_vlan_host_promisc
    assert_equal(val, interface.switchport_mode_private_vlan_host_promisc,
                 'Err: promisc association failed')
  end

  def test_interface_switchport_private_host_promisc
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    v1 = Vlan.new(10)
    v1.private_vlan_type = 'primary'
    v2 = Vlan.new(11)
    v2.private_vlan_type = 'community'
    v1.private_vlan_association = ['11']

    input = %w(10 11)
    interface.switchport_mode_private_vlan_host = :promiscuous
    assert_equal(:promiscuous,
                 interface.switchport_mode_private_vlan_host,
                 'Error: Switchport mode not as expected')
    interface.switchport_mode_private_vlan_host_promisc = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_promisc,
                 'Error: switchport private host promisc not configured')

    v3 = Vlan.new(12)
    v3.private_vlan_type = 'community'

    v1.private_vlan_association = ['12']
    input = %w(10 12)
    interface.switchport_mode_private_vlan_host_promisc = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_promisc,
                 'Error: switchport private host promisc not configured')

    v4 = Vlan.new(12)
    v4.private_vlan_type = 'community'

    v5 = Vlan.new(13)
    v5.private_vlan_type = 'community'

    v6 = Vlan.new(18)
    v6.private_vlan_type = 'community'

    v7 = Vlan.new(30)
    v7.private_vlan_type = 'community'

    v1.private_vlan_association = ['12-13', '18', '30']
    input = %w(10 12-13,18,30)
    interface.switchport_mode_private_vlan_host_promisc = input
    assert_equal(input,
                 interface.switchport_mode_private_vlan_host_promisc,
                 'Error: switchport private host promisc not configured')
  end

  def test_interface_switchport_private_host_promisc_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end

    input = %w(10)
    interface.switchport_mode_private_vlan_host = :promiscuous
    assert_equal(:promiscuous, interface.switchport_mode_private_vlan_host,
                 'Error: Switchport mode not as expected')

    assert_raises(TypeError, 'private vlan host promisc raise typeError') do
      interface.switchport_mode_private_vlan_host_promisc = input
    end

    input = %w(10,)
    assert_raises(TypeError, 'private vlan host promisc raise typeError') do
      interface.switchport_mode_private_vlan_host_promisc = input
    end

    input = %w(10 11 12)

    assert_raises(TypeError, 'private vlan host promisc raise typeError') do
      interface.switchport_mode_private_vlan_host_promisc = input
    end

    input = %w(10 ten)
    assert_raises(CliError) do
      interface.switchport_mode_private_vlan_host_promisc = input
    end

    input = %w(10 10)
    assert_raises(CliError) do
      interface.switchport_mode_private_vlan_host_promisc = input
    end

    input = %w(10 10)
    assert_raises(RuntimeError,
                  'promisc association did not raise RuntimeError') do
      interface.switchport_mode_private_vlan_host_promisc = input
    end
  end

  def test_interface_no_switchport_private_host_promisc
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    v1 = Vlan.new(10)
    v1.private_vlan_type = 'primary'

    v2 = Vlan.new(11)
    v2.private_vlan_type = 'community'
    v1.private_vlan_association = ['11']

    input = %w(10 11)
    interface.switchport_mode_private_vlan_host = :promiscuous
    assert_equal(:promiscuous, interface.switchport_mode_private_vlan_host,
                 'Error: Switchport mode not as expected')

    interface.switchport_mode_private_vlan_host_promisc = input
    assert_equal(input, interface.switchport_mode_private_vlan_host_promisc,
                 'Error: switchport private host promisc not configured')
    input = []
    interface.switchport_mode_private_vlan_host_promisc = input
    assert_equal(input, interface.switchport_mode_private_vlan_host_promisc,
                 'Error: switchport private host promisc not configured')
  end

  def test_interface_switchport_pvlan_trunk_allow_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    val = interface.default_switchport_private_vlan_trunk_allowed_vlan
    assert_equal(val, interface.switchport_private_vlan_trunk_allowed_vlan,
                 'Err: trunk allowed vlan failed')
  end

  def test_interface_switchport_pvlan_trunk_allow_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    input = %w(ten)
    assert_raises(CliError) do
      interface.switchport_private_vlan_trunk_allowed_vlan = input
    end

    input = %w(5000)
    assert_raises(CliError) do
      interface.switchport_private_vlan_trunk_allowed_vlan = input
    end
  end

  def test_interface_switchport_pvlan_trunk_allow
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    input = %w(10)
    interface.switchport_private_vlan_trunk_allowed_vlan = input
    assert_equal(input, interface.switchport_private_vlan_trunk_allowed_vlan,
                 'Error: switchport private trunk allow vlan not configured')

    input = %w(10-20)
    result = %w(10-20)
    interface.switchport_private_vlan_trunk_allowed_vlan = input
    assert_equal(result, interface.switchport_private_vlan_trunk_allowed_vlan,
                 'Error: switchport private trunk allow vlan not configured')

    input = %w(10 13-14 40)
    result = %w(10 13-14 40)
    interface.switchport_private_vlan_trunk_allowed_vlan = input
    assert_equal(result, interface.switchport_private_vlan_trunk_allowed_vlan,
                 'Error: switchport private trunk allow vlan not configured')

    input = []
    interface.switchport_private_vlan_trunk_allowed_vlan = input
    assert_equal(input, interface.switchport_private_vlan_trunk_allowed_vlan,
                 'Error: switchport private trunk allow vlan not configured')
  end

  def test_interface_switchport_pvlan_trunk_native_vlan_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    input = 'ten'
    assert_raises(CliError) do
      interface.switchport_private_vlan_trunk_native_vlan = input
    end

    input = 5000
    assert_raises(CliError) do
      interface.switchport_private_vlan_trunk_native_vlan = input
    end
  end

  def test_interface_switchport_pvlan_trunk_native_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end
    val = interface.default_switchport_private_vlan_trunk_native_vlan
    assert_equal(val, interface.switchport_private_vlan_trunk_native_vlan,
                 'Err: trunk native vlan failed')
  end

  def test_interface_switchport_pvlan_trunk_native_vlan
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')

      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    end

    input = 10
    interface.switchport_private_vlan_trunk_native_vlan = input

    assert_equal(input, interface.switchport_private_vlan_trunk_native_vlan,
                 'Error: switchport private trunk native vlan not configured')
    input = 1
    interface.switchport_private_vlan_trunk_native_vlan = input
    assert_equal(input, interface.switchport_private_vlan_trunk_native_vlan,
                 'Error: switchport private trunk native vlan not configured')
    input = 40
    interface.switchport_private_vlan_trunk_native_vlan = input
    assert_equal(input, interface.switchport_private_vlan_trunk_native_vlan,
                 'Error: switchport private trunk native vlan not configured')

    input = 50
    interface.switchport_private_vlan_trunk_native_vlan = input
    assert_equal(input,
                 interface.switchport_private_vlan_trunk_native_vlan,
                 'Error: switchport private trunk native vlan not configured')
  end

  def test_interface_switchport_pvlan_association_trunk
    if validate_property_excluded?('interface',
                                   'switchport_private_vlan_association_trunk')
      assert_nil(interface.switchport_private_vlan_association_trunk)
      return
    end
    input = %w(10 12)
    result = ['10 12']
    interface.switchport_private_vlan_association_trunk = input
    input = interface.switchport_private_vlan_association_trunk
    refute((result & input).empty?,
           'Err: wrong config for switchport private trunk association')
    input = %w(20 30)
    result = ['20 30']
    interface.switchport_private_vlan_association_trunk = input
    input = interface.switchport_private_vlan_association_trunk
    refute((result & input).empty?,
           'Err: wrong config for switchport private trunk association')

    input = %w(10 13)
    result = ['10 13']
    interface.switchport_private_vlan_association_trunk = input
    input = interface.switchport_private_vlan_association_trunk
    refute((result & input).empty?,
           'Err: wrong config for switchport private trunk association')

    input = []
    interface.switchport_private_vlan_association_trunk = input
    assert_equal(input, interface.switchport_private_vlan_association_trunk,
                 'Err: wrong config for switchport private trunk association')
  end

  def test_interface_switchport_pvlan_trunk_assoc_vlan_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_private_vlan_association_trunk')
      assert_nil(interface.switchport_private_vlan_association_trunk)
      return
    end
    input = %w(10 10)
    assert_raises(CliError) do
      interface.switchport_private_vlan_association_trunk = input
    end

    input = %w(10 5000)
    assert_raises(CliError) do
      interface.switchport_private_vlan_association_trunk = input
    end

    input = %w(10)
    assert_raises(CliError) do
      interface.switchport_private_vlan_association_trunk = input
    end

    input = '10'
    assert_raises(TypeError,
                  'private vlan trunk association raise typeError') do
      interface.switchport_private_vlan_association_trunk = input
    end
  end

  def test_interface_switchport_pvlan_trunk_assocciation_default
    if validate_property_excluded?('interface',
                                   'switchport_private_vlan_association_trunk')
      assert_nil(interface.switchport_private_vlan_association_trunk)
      return
    end
    val = interface.default_switchport_private_vlan_association_trunk
    assert_equal(val, interface.switchport_private_vlan_association_trunk,
                 'Err: association trunk failed')
  end

  def test_interface_switchport_pvlan_mapping_trunk_default
    if validate_property_excluded?('interface',
                                   'switchport_private_vlan_mapping_trunk')

      assert_nil(interface.switchport_private_vlan_mapping_trunk)
      return
    end
    val = interface.default_switchport_private_vlan_mapping_trunk
    assert_equal(val, interface.switchport_private_vlan_mapping_trunk,
                 'Err: mapping trunk failed')
  end

  def test_interface_switchport_pvlan_mapping_trunk
    if validate_property_excluded?('interface',
                                   'switchport_private_vlan_mapping_trunk')
      assert_nil(interface.switchport_private_vlan_mapping_trunk)
      return
    end
    input = %w(10 11)
    result = '10 11'
    interface.switchport_private_vlan_mapping_trunk = input
    input = interface.switchport_private_vlan_mapping_trunk
    assert_includes(input, result,
                    'Err: wrong config for switchport private mapping trunk ')

    input = %w(10 12)
    result = '10 12'
    interface.switchport_private_vlan_mapping_trunk = input
    input = interface.switchport_private_vlan_mapping_trunk
    assert_includes(input, result,
                    'Err: wrong config for switchport private mapping trunk ')

    input = %w(20 21)
    result = '20 21'
    interface.switchport_private_vlan_mapping_trunk = input
    input = interface.switchport_private_vlan_mapping_trunk
    assert_includes(input, result,
                    'Err: wrong config for switchport private mapping trunk ')

    input = []
    interface.switchport_private_vlan_mapping_trunk = input
    assert_equal(input, interface.switchport_private_vlan_mapping_trunk)
  end

  def test_interface_switchport_pvlan_mapping_trunk_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_private_vlan_mapping_trunk')
      assert_nil(interface.switchport_private_vlan_mapping_trunk)
      return
    end
    input = %w(10 10)
    assert_raises(CliError) do
      interface.switchport_private_vlan_mapping_trunk = input
    end

    input = %w(10 5000)
    assert_raises(CliError) do
      interface.switchport_private_vlan_mapping_trunk = input
    end

    input = %w(10)
    assert_raises(CliError) do
      interface.switchport_private_vlan_mapping_trunk = input
    end

    input = '10'
    assert_raises(TypeError,
                  'private vlan mapping trunk raise typeError') do
      interface.switchport_private_vlan_mapping_trunk = input
    end

    input = %w(10 20-148)
    assert_raises(RuntimeError,
                  'mapping trunk did not raise RuntimeError') do
      interface.switchport_private_vlan_mapping_trunk = input
    end
  end
end
