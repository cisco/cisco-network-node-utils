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
require_relative '../lib/cisco_node_utils/vtp'

include Cisco

# TestInterfaceSwitchport
# Parent class for specific types of switchport tests (below)
class TestInterfaceSwitchport < CiscoTestCase
  attr_reader :interface

  def platform_supports_vtp_switchport_access?
    skip('Platform does not support VTP when switchport mode is access') if
      node.product_id =~ /N(5|6|7)/
  end

  def setup
    super
    config_no_warn('no feature vtp', 'no feature interface-vlan')
    @interface = Interface.new(interfaces[0])
  end

  def teardown
    interface_ethernet_default(interfaces[0])
    super
  end

  def interface_ethernet_default(ethernet_intf)
    config("default interface #{ethernet_intf}")
  end

  def mgmt_intf
    if platform == :nexus
      'mgmt0'
    elsif platform == :ios_xr
      'MgmtEth0/RP0/CPU0/0'
    end
  end
end

# TestSwitchport - general interface switchport tests.
class TestSwitchport < TestInterfaceSwitchport
  DEFAULT_IF_ACCESS_VLAN = 1
  DEFAULT_IF_SWITCHPORT_NATIVE_VLAN = 1

  def system_default_switchport(state='')
    config("#{state} system default switchport")
  end

  def system_default_switchport_shutdown(state='')
    config("#{state} system default switchport shutdown")
  end

  def test_access_vlan
    interface.switchport_mode = :disabled
    if platform == :ios_xr
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode = :access
      end
      assert_nil(interface.access_vlan)
    else
      interface.switchport_mode = :access
      assert_equal(DEFAULT_IF_ACCESS_VLAN, interface.access_vlan)
    end
  end

  def test_access_vlan_sw_disabled
    interface.switchport_mode = :disabled
    if platform == :ios_xr
      assert_nil(interface.access_vlan)
    else
      assert_equal(DEFAULT_IF_ACCESS_VLAN, interface.access_vlan)
    end
  end

  def test_access_vlan_sw_trunk
    interface.switchport_mode = :disabled
    if platform == :ios_xr
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode = :trunk
      end
      assert_nil(interface.access_vlan)
    else
      interface.switchport_mode = :trunk
      assert_equal(DEFAULT_IF_ACCESS_VLAN, interface.access_vlan)
    end
  end

  def test_sw_vtp_disabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')

    # mgmt
    interface = Interface.new(mgmt_intf)
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')

    # no switchport
    interface.switchport_mode = :disabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_sw_vtp_disabled_fex
    if validate_property_excluded?('feature', 'fex')
      assert_raises(Cisco::UnsupportedError) do
        Feature.fex_enable
      end
      return
    end
    if validate_property_excluded?('interface', 'switchport')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode = :fex_fabric
      end
      return
    end
    interface.switchport_mode = :fex_fabric
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  rescue Cisco::CliError => e
    incompatible_interface?(e.message)
  end

  def test_sw_autostate_disabled
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')

    # mgmt
    interface = Interface.new(mgmt_intf)
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')

    # no switchport
    if platform == :ios_xr
      assert_nil(interface.switchport_autostate_exclude)
    else
      interface.switchport_mode = :disabled
      refute(interface.switchport_autostate_exclude,
             'Error: interface, access, autostate exclude not disabled')
    end
  end

  def test_sw_mode_disabled
    if platform == :ios_xr
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_autostate_exclude = true
      end
    else
      interface.switchport_enable(false)

      assert_raises(RuntimeError) do
        interface.switchport_autostate_exclude = true
      end
    end
  end

  def test_sw_mode_invalid
    assert_raises(ArgumentError) { interface.switchport_mode = :unknown }

    interface = Interface.new(mgmt_intf)
    assert_raises(Cisco::CliError, Cisco::UnsupportedError) do
      interface.switchport_mode = :access
    end
  end

  def test_sw_mode_valid
    if platform == :ios_xr
      # We don't support any switchport modes on IOS XR
      # but we allow the user to set :disabled since that's the default.
      interface.switchport_mode = :disabled
      assert_nil(interface.switchport_mode)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode = :access
      end
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode = :trunk
      end
      assert_nil(interface.switchport_mode)
      return
    end

    switchport_modes = [
      :unknown,
      :disabled,
      :access,
      :trunk,
      :tunnel,
    ]

    switchport_modes.each do |start|
      switchport_modes.each do |finish|
        next if start == :unknown || finish == :unknown
        begin
          # puts "#{start},#{finish}"
          interface.switchport_mode = start
          assert_equal(start, interface.switchport_mode,
                       "Error: Switchport mode, #{start}, not as expected")
          # puts "now finish #{finish}"
          interface.switchport_mode = finish
          assert_equal(finish, interface.switchport_mode,
                       "Error: Switchport mode, #{finish}, not as expected")
        rescue Cisco::CliError
          next
        end
      end
    end
  end

  def test_sw_mode_valid_fex
    if validate_property_excluded?('feature', 'fex')
      assert_raises(Cisco::UnsupportedError) do
        Feature.fex_enable
      end
      return
    end
    if validate_property_excluded?('interface', 'switchport')
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode = :fex_fabric
      end
      return
    end

    interface.switchport_mode = :fex_fabric
  rescue Cisco::CliError => e
    incompatible_interface?(e.message)
  end

  def test_sw_trunk_allowed_vlan
    if platform == :ios_xr
      assert_nil(interface.default_switchport_trunk_allowed_vlan)
      assert_nil(interface.switchport_trunk_allowed_vlan)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_trunk_allowed_vlan = 'all'
      end
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_trunk_allowed_vlan = '20'
      end
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_trunk_allowed_vlan = 'none'
      end
    else
      interface.switchport_enable
      interface.switchport_trunk_allowed_vlan = 'all'
      assert_equal(interface.default_switchport_trunk_allowed_vlan,
                   interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan = '20'
      assert_equal('20', interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan = '30'
      assert_equal('30', interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan =
        interface.default_switchport_trunk_allowed_vlan
      assert_equal(interface.default_switchport_trunk_allowed_vlan,
                   interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan = 'none'
      assert_equal('none', interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan = '20, 30'
      assert_equal('20,30', interface.switchport_trunk_allowed_vlan)

      # Some images have behavior where 'vlan add' is separate line
      # This behavior is triggered for vlan ranges that exceed character limit
      vlans = '500-528,530,532,534,587,590-593,597-598,600,602,604'
      interface.switchport_trunk_allowed_vlan = vlans
      assert_equal(vlans, interface.switchport_trunk_allowed_vlan)
    end
  end

  def test_sw_trunk_native_vlan
    if platform == :ios_xr
      assert_nil(interface.switchport_trunk_native_vlan)
      assert_nil(interface.default_switchport_trunk_native_vlan)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_trunk_native_vlan = 20
      end
    else
      interface.switchport_enable

      interface.switchport_trunk_native_vlan = 20
      assert_equal(20, interface.switchport_trunk_native_vlan)

      interface.switchport_trunk_native_vlan = 30
      assert_equal(30, interface.switchport_trunk_native_vlan)

      interface.switchport_trunk_native_vlan =
        interface.default_switchport_trunk_native_vlan
      assert_equal(DEFAULT_IF_SWITCHPORT_NATIVE_VLAN,
                   interface.switchport_trunk_native_vlan)
    end
  end

  def test_sys_def_sw_on_off
    if platform == :nexus
      system_default_switchport('')
      assert(interface.system_default_switchport,
             'Test for enabled - failed')

      # common default is "no switch"
      system_default_switchport('no ')
    end
    refute(interface.system_default_switchport,
           'Test for disabled - failed')
  rescue RuntimeError => e
    skip('NX-OS defect: system default switchport nvgens twice') if
      e.message[/Expected zero.one value/]
    flunk(e.message)
  end

  def test_sys_def_sw_shut_on_off
    if platform == :nexus
      system_default_switchport_shutdown('no ')
      refute(interface.system_default_switchport_shutdown,
             'Test for disabled - failed')

      # common default is "shutdown"
      system_default_switchport_shutdown('')
    end
    assert(interface.system_default_switchport_shutdown,
           'Test for enabled - failed')
  end

  def test_svi_cmd_on_non_vlan
    assert_raises(RuntimeError) { interface.svi_autostate = true }
    assert_raises(RuntimeError) { interface.svi_management = true }
  end
end

# TestInterfaceSwitchportSvi
# Minitest for Interface switchport configuration in combo with interface-vlan
# Not applicable to IOS XR
class TestInterfaceSwSvi < TestInterfaceSwitchport
  attr_reader :svi

  def setup
    super
    skip('VLAN interfaces are not supported on IOS XR') if platform == :ios_xr
    @svi = Interface.new('Vlan23')
  end

  def teardown
    svi.destroy unless platform == :ios_xr || svi.nil?
    super
  end

  def test_sw_autostate
    i = interface
    if validate_property_excluded?('interface', 'switchport_autostate_exclude')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_autostate_exclude = false
      end
      return
    end

    default = i.default_switchport_autostate_exclude

    # access
    i.switchport_mode = :access
    assert_equal(default, i.switchport_autostate_exclude)

    i.switchport_autostate_exclude = true
    assert(i.switchport_autostate_exclude)

    i.switchport_autostate_exclude = false
    refute(i.switchport_autostate_exclude)

    i.switchport_autostate_exclude = default
    assert_equal(default, i.switchport_autostate_exclude)

    # trunk
    i.switchport_mode = :trunk
    i.switchport_autostate_exclude = true
    assert(i.switchport_autostate_exclude)

    i.switchport_autostate_exclude = false
    refute(i.switchport_autostate_exclude)

    i.switchport_autostate_exclude = default
    assert_equal(default, i.switchport_autostate_exclude)

    # disabled
    interface.switchport_mode = :disabled
    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = true
    end

    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = false
    end
  end
end

# TestInterfaceSwitchportVtp
# Minitest for Interface switchport configuration in combo with Vtp class
# Not applicable to IOS XR
class TestInterfaceSwVtp < TestInterfaceSwitchport
  attr_reader :vtp

  def setup
    super
    skip('VTP is not supported on IOS XR') if platform == :ios_xr
    @vtp = Vtp.new(true)
  end

  def teardown
    vtp.destroy unless platform == :ios_xr
    super
  end

  def test_mode_access
    # Basic test
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')

    # Now :access
    platform_supports_vtp_switchport_access?
    interface.switchport_mode = :access

    default = interface.default_switchport_vtp
    assert_equal(default, interface.switchport_vtp)

    interface.switchport_vtp = true
    assert(interface.switchport_vtp)

    interface.switchport_vtp = false
    refute(interface.switchport_vtp)

    interface.switchport_vtp = default
    assert_equal(default, interface.switchport_vtp)
  end

  def test_mode_trunk
    platform_supports_vtp_switchport_access?
    interface.switchport_mode = :trunk

    default = interface.default_switchport_vtp
    assert_equal(default, interface.switchport_vtp)

    interface.switchport_vtp = true
    assert(interface.switchport_vtp)

    interface.switchport_vtp = false
    refute(interface.switchport_vtp)

    interface.switchport_vtp = default
    assert_equal(default, interface.switchport_vtp)
  end

  def test_mode_disabled
    platform_supports_vtp_switchport_access?
    interface.switchport_mode = :disabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp is enabled')
  end
end
