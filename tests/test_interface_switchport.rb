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
  DEFAULT_IF_SWITCHPORT_ALLOWED_VLAN = '1-4094'
  DEFAULT_IF_SWITCHPORT_NATIVE_VLAN = 1

  def system_default_switchport(state='')
    config("#{state} system default switchport")
  end

  def system_default_switchport_shutdown(state='')
    config("#{state} system default switchport shutdown")
  end

  def test_interface_get_access_vlan
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

  def test_interface_get_access_vlan_switchport_disabled
    interface.switchport_mode = :disabled
    if platform == :ios_xr
      assert_nil(interface.access_vlan)
    else
      assert_equal(DEFAULT_IF_ACCESS_VLAN, interface.access_vlan)
    end
  end

  def test_interface_get_access_vlan_switchport_trunk
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

  def test_switchport_vtp_disabled_feature_disabled_eth1_1
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_switchport_vtp_disabled_feature_disabled_mgmt_intf
    interface = Interface.new(mgmt_intf)
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_switchport_vtp_disabled_unsupported_mode_disabled
    interface.switchport_mode = :disabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_switchport_vtp_disabled_unsupported_mode_fex
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
    msg = "[#{interfaces[0]}] switchport_mode is not supported " \
          'on this interface'
    assert_equal(msg.downcase, e.message)
  end

  def test_switchport_autostate_disabled_feature_disabled_eth1_1
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_disabled_feature_disabled_mgmt_intf
    interface = Interface.new(mgmt_intf)
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_disabled_unsupported_mode
    if platform == :ios_xr
      assert_nil(interface.switchport_autostate_exclude)
    else
      interface.switchport_mode = :disabled
      refute(interface.switchport_autostate_exclude,
             'Error: interface, access, autostate exclude not disabled')
    end
  end

  def test_raise_error_switchport_not_enabled
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

  def test_interface_switchport_mode_invalid
    assert_raises(ArgumentError) { interface.switchport_mode = :unknown }
  end

  def test_interface_switchport_mode_not_supported
    interface = Interface.new(mgmt_intf)
    assert_raises(Cisco::CliError, Cisco::UnsupportedError) do
      interface.switchport_mode = :access
    end
  end

  def test_interface_switchport_mode_valid
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

  def test_interface_switchport_mode_valid_fex
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
    assert_equal(interface.switchport_mode, :fex_fabric)
  end

  def test_interface_switchport_trunk_allowed_vlan
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
      assert_equal(DEFAULT_IF_SWITCHPORT_ALLOWED_VLAN,
                   interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan = '20'
      assert_equal('20', interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan = '30'
      assert_equal('30', interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan =
        interface.default_switchport_trunk_allowed_vlan
      assert_equal(DEFAULT_IF_SWITCHPORT_ALLOWED_VLAN,
                   interface.switchport_trunk_allowed_vlan)

      assert_raises(RuntimeError) do
        interface.switchport_trunk_allowed_vlan = 'hello'
      end

      interface.switchport_trunk_allowed_vlan = 'none'
      assert_equal('none', interface.switchport_trunk_allowed_vlan)

      interface.switchport_trunk_allowed_vlan = '20, 30'
      assert_equal('20,30', interface.switchport_trunk_allowed_vlan)
    end
  end

  def test_interface_switchport_trunk_native_vlan
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

      assert_raises(RuntimeError) do
        interface.switchport_trunk_native_vlan = '20, 30'
      end
    end
  end

  def test_system_default_switchport_on_off
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

  def test_system_default_switchport_shutdown_on_off
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

  def test_interface_svi_command_on_non_vlan
    assert_raises(RuntimeError) { interface.svi_autostate = true }
    assert_raises(RuntimeError) { interface.svi_management = true }
  end
end

# TestInterfaceSwitchportSvi
# Minitest for Interface switchport configuration in combo with interface-vlan
# Not applicable to IOS XR
class TestInterfaceSwitchportSvi < TestInterfaceSwitchport
  attr_reader :svi

  def setup
    super
    skip('VLAN interfaces are not supported on IOS XR') if platform == :ios_xr
    @svi = Interface.new('Vlan23')
  end

  def teardown
    svi.destroy unless platform == :ios_xr
    super
  end

  def cmd_ref_switchport_autostate_exclude
    ref = cmd_ref.lookup('interface',
                         'switchport_autostate_exclude')
    assert(ref, 'Error, reference not found for switchport_autostate_exclude')
    ref
  end

  def test_switchport_autostate_disabled_feature_enabled
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_enabled_access
    config("interface ethernet #{interfaces_id[0]}",
           'switchport',
           'switchport autostate exclude')

    cmd_ref = cmd_ref_switchport_autostate_exclude
    if cmd_ref.setter?
      assert(interface.switchport_autostate_exclude,
             'Error: interface, access, autostate exclude not enabled')
    else
      assert_equal(interface.default_switchport_autostate_exclude,
                   interface.switchport_autostate_exclude,
                   'Error: interface, access, autostate exclude not disabled')
    end
  end

  def test_switchport_autostate_disabled_access
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_enabled_trunk
    interface.switchport_mode = :trunk
    config("interface ethernet #{interfaces_id[0]}",
           'switchport autostate exclude')

    cmd_ref = cmd_ref_switchport_autostate_exclude
    if cmd_ref.setter?
      assert(interface.switchport_autostate_exclude,
             'Error: interface, access, autostate exclude not enabled')
    else
      assert_equal(interface.default_switchport_autostate_exclude,
                   interface.switchport_autostate_exclude,
                   'Error: interface, access, autostate exclude not disabled')
    end
  end

  def test_switchport_autostate_disabled_trunk
    interface.switchport_mode = :trunk
    config("interface ethernet #{interfaces_id[0]}",
           'no switchport autostate exclude')

    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_access
    # switchport must be enabled to configure autostate
    interface.switchport_enable(true)

    interface.switchport_autostate_exclude = true
    assert(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not enabled')

    interface.switchport_autostate_exclude = false
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')

    result = interface.default_switchport_autostate_exclude
    interface.switchport_autostate_exclude = result
    assert_equal(result, interface.switchport_autostate_exclude,
                 'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_trunk
    interface.switchport_mode = :trunk

    # switchport must be enabled to configure autostate
    interface.switchport_enable(true)

    interface.switchport_autostate_exclude = true
    assert(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not enabled')

    interface.switchport_autostate_exclude = false
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')

    result = interface.default_switchport_autostate_exclude
    interface.switchport_autostate_exclude = result
    assert_equal(result, interface.switchport_autostate_exclude,
                 'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_unsupported_mode_disabled
    interface.switchport_mode = :disabled

    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = true
    end
    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = false
    end
  end

  def test_set_switchport_autostate_true_unsupported_mgmt_intf
    interface = Interface.new(mgmt_intf)
    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = true
    end
  end
end

# TestInterfaceSwitchportVtp
# Minitest for Interface switchport configuration in combo with Vtp class
# Not applicable to IOS XR
class TestInterfaceSwitchportVtp < TestInterfaceSwitchport
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

  def test_switchport_vtp_disabled_feature_enabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_switchport_vtp_enabled_access
    platform_supports_vtp_switchport_access?
    interface.switchport_mode = :access
    config("interface ethernet #{interfaces_id[0]}", 'vtp')

    assert(interface.switchport_vtp,
           'Error: interface, access, vtp not enabled')
  end

  def test_switchport_vtp_disabled_access
    interface.switchport_mode = :access
    config("interface ethernet #{interfaces_id[0]}", 'no vtp')

    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_switchport_vtp_enabled_trunk
    interface.switchport_mode = :trunk
    config("interface ethernet #{interfaces_id[0]}", 'vtp')

    assert(interface.switchport_vtp,
           'Error: interface, trunk, vtp not enabled')
  end

  def test_switchport_vtp_disabled_trunk
    interface.switchport_mode = :trunk
    refute(interface.switchport_vtp,
           'Error: interface, trunk, vtp not disabled')
  end

  def test_set_switchport_vtp_default_access
    platform_supports_vtp_switchport_access?
    interface.switchport_mode = :access

    interface.switchport_vtp = interface.default_switchport_vtp
    refute(interface.switchport_vtp,
           'Error:(1) mode :access, vtp should be default (false)')

    interface.switchport_vtp = true
    assert(interface.switchport_vtp,
           'Error:(2) mode :access, vtp should be true')

    interface.switchport_vtp = interface.default_switchport_vtp
    refute(interface.switchport_vtp,
           'Error:(3) mode :access, vtp should be default (false)')
  end

  def test_set_switchport_vtp_default_trunk
    interface.switchport_mode = :trunk
    interface.switchport_vtp = interface.default_switchport_vtp
    refute(interface.switchport_vtp,
           'Error:(1) mode :trunk, vtp should be default (false)')

    interface.switchport_vtp = true
    assert(interface.switchport_vtp,
           'Error:(2) mode :trunk, vtp should be true')

    interface.switchport_vtp = interface.default_switchport_vtp
    refute(interface.switchport_vtp,
           'Error:(3) mode :trunk, vtp should be default (false)')
  end

  def test_set_switchport_vtp_true_access
    platform_supports_vtp_switchport_access?
    interface.switchport_mode = :access
    interface.switchport_vtp = true
    assert(interface.switchport_vtp,
           'Error: interface, access, vtp not enabled')
  end

  def test_set_switchport_vtp_true_trunk
    interface.switchport_mode = :trunk
    interface.switchport_vtp = true
    assert(interface.switchport_vtp,
           'Error: interface, access, vtp not enabled')
  end

  def test_set_switchport_vtp_true_unsupported_mode_disabled
    interface.switchport_mode = :disabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp is enabled')
  end

  def test_set_switchport_vtp_true_unsupported_mgmt_intf
    interface = Interface.new(mgmt_intf)

    interface.switchport_vtp = true
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp is enabled')
  end

  def test_set_switchport_vtp_false_access
    interface.switchport_mode = :access
    interface.switchport_vtp = false
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_set_switchport_vtp_false_trunk
    interface.switchport_mode = :trunk
    interface.switchport_vtp = false
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_set_switchport_vtp_false_unsupported_mode_disabled
    interface.switchport_mode = :disabled
    interface.switchport_vtp = false
    refute(interface.switchport_vtp,
           'Error: mode :disabled, vtp should be false')
  end

  def test_default_switchport_vtp
    [:access, :disabled].each do |mode|
      interface.switchport_mode = mode
      interface.switchport_vtp = interface.default_switchport_vtp
      assert_equal(interface.switchport_vtp, interface.default_switchport_vtp,
                   "Error: mode :#{mode}, "\
                   'switchport_vtp should equal default_switchport_vtp')
    end
  end
end
