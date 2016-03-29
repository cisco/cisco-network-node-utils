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

include Cisco

# TestInterfaceSwitchport
# Parent class for specific types of switchport tests (below)
class TestInterfaceSwitchport < CiscoTestCase
  attr_reader :interface

  def setup
    super
    config('feature private-vlan', 'no feature vtp')
    @interface = Interface.new(interfaces[0])
  end

  def teardown
    config("default interface ethernet #{interfaces_id[0]}")
    config('no feature private-vlan')
    super
  end
end

# TestSwitchport - general interface switchport tests.
class TestSwitchport < TestInterfaceSwitchport
  def test_interface_switchport_private_host_mode
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else
      switchport_modes = [
        :host,
        :promiscuous,
      ]

      switchport_modes.each do |start|
        begin
          interface.switchport_mode_private_vlan_host = start
          assert_equal(start, interface.switchport_mode_private_vlan_host,
                       "Error: Switchport mode, #{start}, not as expected")
        rescue Cisco::CliError
          next
        end
      end
    end
  end

  def test_interface_switchport_private_trunk_mode
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_trunk')
      assert_nil(interface.switchport_mode_private_vlan_trunk)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_trunk = :secondary
      end
      return
    else
      switchport_modes = [
        :promiscuous,
        :secondary,
      ]

      switchport_modes.each do |start|
        begin
          interface.switchport_mode_private_vlan_trunk = start
          assert_equal(start, interface.switchport_mode_private_vlan_trunk,
                       "Error: Switchport mode, #{start}, not as expected")
        rescue Cisco::CliError
          next
        end
      end
    end
  end

  def test_interface_no_switchport_private_host_mode
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else
      switchport_modes = [
        :host,
        :promiscuous,
      ]

      switchport_modes.each do |start|
        begin
          interface.switchport_mode_private_vlan_host = start
          assert_equal(start, interface.switchport_mode_private_vlan_host,
                       "Error: Switchport mode, #{start}, not as expected")
          interface.switchport_mode_private_vlan_host = :disabled
          assert_equal(:disabled, interface.switchport_mode_private_vlan_host,
                       'Error: Switchport mode not disabled')
        rescue Cisco::CliError
          next
        end
      end
    end
  end

  def test_interface_no_switchport_private_trunk_mode
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_trunk')
      assert_nil(interface.switchport_mode_private_vlan_trunk)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_trunk = :secondary
      end
      return
    else
      switchport_modes = [
        :promiscuous,
        :secondary,
      ]

      switchport_modes.each do |start|
        begin
          interface.switchport_mode_private_vlan_trunk = start
          assert_equal(start, interface.switchport_mode_private_vlan_trunk,
                       "Error: Switchport mode, #{start}, not as expected")
          interface.switchport_mode_private_vlan_trunk = :disabled
          assert_equal(:disabled, interface.switchport_mode_private_vlan_trunk,
                       'Error: Switchport mode not disabled')

        rescue Cisco::CliError
          next
        end
      end
    end
  end

  def test_interface_switchport_private_host_association
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      input = %w(10 11)
      result = %w(10 11)
      interface.switchport_mode_private_vlan_host = :host
      assert_equal(:host, interface.switchport_mode_private_vlan_host,
                   'Error: Switchport mode not as expected')
      interface.switchport_mode_private_vlan_host_association = input
      assert_equal(result,
                   interface.switchport_mode_private_vlan_host_association,
                   'Error: switchport private host_association not configured')

    end
  end

  def test_interface_switchport_pvlan_host_assoc_change
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      input = %w(10 11)
      result = %w(10 11)
      interface.switchport_mode_private_vlan_host = :host
      assert_equal(:host, interface.switchport_mode_private_vlan_host,
                   'Error: Switchport mode not as expected')
      interface.switchport_mode_private_vlan_host_association = input
      assert_equal(result,
                   interface.switchport_mode_private_vlan_host_association,
                   'Error: switchport private host_association not configured')

      input = %w(20 21)
      result = %w(20 21)
      interface.switchport_mode_private_vlan_host_association = input
      assert_equal(result,
                   interface.switchport_mode_private_vlan_host_association,
                   'Error: switchport private host_association not configured')

    end
  end

  def test_interface_switchport_no_pvlan_host_assoc
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      input = %w(10 11)
      result = %w(10 11)
      interface.switchport_mode_private_vlan_host = :host
      assert_equal(:host, interface.switchport_mode_private_vlan_host,
                   'Error: Switchport mode not as expected')
      interface.switchport_mode_private_vlan_host_association = input
      assert_equal(result,
                   interface.switchport_mode_private_vlan_host_association,
                   'Error: switchport private host_association not configured')

      input = []
      result = []
      interface.switchport_mode_private_vlan_host_association = input
      assert_equal(result,
                   interface.switchport_mode_private_vlan_host_association,
                   'Error: switchport private host_association not configured')

    end
  end

  def test_interface_switchport_pvlan_host_assoc_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      result = []
      assert_equal(result,
                   interface.switchport_mode_private_vlan_host_association,
                   'Error: switchport private host_association not configured')

    end
  end

  def test_interface_switchport_pvlan_host_assoc_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      input = %w(10)
      interface.switchport_mode_private_vlan_host = :host
      assert_equal(:host, interface.switchport_mode_private_vlan_host,
                   'Error: Switchport mode not as expected')

      assert_raises(TypeError, 'private vlan host assoc raise typeError') do
        interface.switchport_mode_private_vlan_host_association = input
      end

      input = %w(10 ten)
      assert_raises(TypeError, 'private vlan host assoc raise typeError') do
        interface.switchport_mode_private_vlan_host_association = input
      end

      input = %w(10 17 12)
      assert_raises(TypeError, 'private vlan host assoc raise typeError') do
        interface.switchport_mode_private_vlan_host_association = input
      end

      input = %w(10,12)
      assert_raises(TypeError, 'private vlan host assoc raise typeError') do
        interface.switchport_mode_private_vlan_host_association = input
      end

    end
  end

  def test_interface_switchport_pvlan_host_primisc_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      result = []
      assert_equal(result, interface.switchport_mode_private_vlan_host_promisc,
                   'Error: switchport private host_promisc not configured')

    end
  end

  def test_interface_switchport_private_host_promisc
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      input = %w(10 11)
      interface.switchport_mode_private_vlan_host = :promiscuous
      assert_equal(:promiscuous, interface.switchport_mode_private_vlan_host,
                   'Error: Switchport mode not as expected')
      interface.switchport_mode_private_vlan_host_promisc = input
      assert_equal(input, interface.switchport_mode_private_vlan_host_promisc,
                   'Error: switchport private host promisc not configured')

      input = %w(10 12)
      interface.switchport_mode_private_vlan_host_promisc = input
      assert_equal(input, interface.switchport_mode_private_vlan_host_promisc,
                   'Error: switchport private host promisc not configured')

      input = %w(10 12-14,18,30-33)
      interface.switchport_mode_private_vlan_host_promisc = input
      assert_equal(input, interface.switchport_mode_private_vlan_host_promisc,
                   'Error: switchport private host promisc not configured')

    end
  end

  def test_interface_switchport_private_host_promisc_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

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

    end
  end

  def test_interface_no_switchport_private_host_promisc
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

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
  end

  def test_interface_switchport_pvlan_trunk_allow_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else
      result = []
      assert_equal(result, interface.switchport_private_vlan_trunk_allowed_vlan,
                   'Error: wrong config for switchport private trunk allowed')
    end
  end

  def test_interface_switchport_pvlan_trunk_allow_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else
      input = %w(ten)
      assert_raises(CliError) do
        interface.switchport_private_vlan_trunk_allowed_vlan = input
      end

      input = %w(5000)
      assert_raises(CliError) do
        interface.switchport_private_vlan_trunk_allowed_vlan = input
      end

    end
  end

  def test_interface_switchport_pvlan_trunk_allow
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      input = %w(10)
      result = %w(10)
      interface.switchport_private_vlan_trunk_allowed_vlan = input
      assert_equal(result, interface.switchport_private_vlan_trunk_allowed_vlan,
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
  end

  def test_interface_switchport_pvlan_trunk_native_vlan_bad_arg
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else
      input = 'ten'
      assert_raises(CliError) do
        interface.switchport_private_vlan_trunk_native_vlan = input
      end

      input = '5000'
      assert_raises(CliError) do
        interface.switchport_private_vlan_trunk_native_vlan = input
      end

      input = '50 10'
      assert_raises(CliError) do
        interface.switchport_private_vlan_trunk_native_vlan = input
      end
    end
  end

  def test_interface_switchport_pvlan_trunk_native_default
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else
      result = ''
      assert_equal(result, interface.switchport_private_vlan_trunk_native_vlan,
                   'Error: wrong config for switchport private native vlan')
    end
  end

  def test_interface_switchport_pvlan_trunk_native_vlan
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = :host
      end
      return
    else

      input = '10'
      result = '10'
      interface.switchport_private_vlan_trunk_native_vlan = input

      assert_equal(result, interface.switchport_private_vlan_trunk_native_vlan,
                   'Error: switchport private trunk native vlan not configured')
      input = ''
      result = '1'
      interface.switchport_private_vlan_trunk_native_vlan = input
      assert_equal(result, interface.switchport_private_vlan_trunk_native_vlan,
                   'Error: switchport private trunk native vlan not configured')
      input = '40'
      result = '40'
      interface.switchport_private_vlan_trunk_native_vlan = input
      assert_equal(result, interface.switchport_private_vlan_trunk_native_vlan,
                   'Error: switchport private trunk native vlan not configured')

      input = '50'
      result = '50'
      interface.switchport_private_vlan_trunk_native_vlan = input
      assert_equal(result, interface.switchport_private_vlan_trunk_native_vlan,
                   'Error: switchport private trunk native vlan not configured')
    end
  end
end
