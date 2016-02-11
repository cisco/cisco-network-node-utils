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

# TestInterfaceSwitchport - Minitest for switchport config by Interface class.
class TestInterfaceSwitchport < CiscoTestCase
  DEFAULT_IF_SWITCHPORT_ALLOWED_VLAN = '1-4094'
  DEFAULT_IF_SWITCHPORT_NATIVE_VLAN = 1

  def setup
    super
    config('no feature vtp', 'no feature interface-vlan')
  end

  def interface_ethernet_default(ethernet_id)
    config("default interface ethernet #{ethernet_id}")
  end

  def cmd_ref_switchport_autostate_exclude
    ref = cmd_ref.lookup('interface',
                         'switchport_autostate_exclude')
    assert(ref, 'Error, reference not found for switchport_autostate_exclude')
    ref
  end

  # Decides whether to check for a raised Exception or an equal value.
  def assert_result(expected_result, err_msg, &block)
    if expected_result.is_a? Class
      assert_raises(expected_result, &block)
    else
      value = block.call
      assert_equal(expected_result, value, err_msg)
    end
  end

  def platform_supports_vtp_switchport_access?
    skip('Platform does not support VTP when switchport mode is access') if
      node.product_id =~ /N(5|6|7)/
  end

  def system_default_switchport(state='')
    config("#{state} system default switchport")
  end

  def system_default_switchport_shutdown(state='')
    config("#{state} system default switchport shutdown")
  end

  def test_switchport_vtp_disabled_feature_enabled
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
    vtp.destroy
  end

  def test_switchport_vtp_disabled_feature_disabled_eth1_1
    interface = Interface.new(interfaces[0])
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_switchport_vtp_disabled_feature_disabled_mgmt0
    interface = Interface.new('mgmt0')
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
  end

  def test_switchport_vtp_disabled_unsupported_mode_disabled
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_vtp_disabled_unsupported_mode_fex
    begin
      interface = Interface.new(interfaces[0])
      interface.switchport_mode = :fex_fabric
      refute(interface.switchport_vtp,
             'Error: interface, access, vtp not disabled')
    rescue RuntimeError => e
      msg = "[#{interfaces[0]}] switchport_mode is not supported " \
            'on this interface'
      assert_equal(msg.downcase, e.message)
    end
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_vtp_enabled_access
    platform_supports_vtp_switchport_access?
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :access
    config("interface ethernet #{interfaces_id[0]}", 'vtp')

    assert(interface.switchport_vtp,
           'Error: interface, access, vtp not enabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_vtp_disabled_access
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :access
    config("interface ethernet #{interfaces_id[0]}", 'no vtp')

    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_vtp_enabled_trunk
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :trunk
    config("interface ethernet #{interfaces_id[0]}", 'vtp')

    assert(interface.switchport_vtp,
           'Error: interface, trunk, vtp not enabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_vtp_disabled_trunk
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

    interface.switchport_mode = :trunk
    refute(interface.switchport_vtp,
           'Error: interface, trunk, vtp not disabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_default_access
    platform_supports_vtp_switchport_access?
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])
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

    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_default_trunk
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

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
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_true_access
    platform_supports_vtp_switchport_access?
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

    interface.switchport_mode = :access
    interface.switchport_vtp = true
    assert(interface.switchport_vtp,
           'Error: interface, access, vtp not enabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_true_trunk
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

    interface.switchport_mode = :trunk
    interface.switchport_vtp = true
    assert(interface.switchport_vtp,
           'Error: interface, access, vtp not enabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_true_unsupported_mode_disabled
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

    interface.switchport_mode = :disabled
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp is enabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_true_unsupported_mgmt0
    vtp = Vtp.new(true)
    interface = Interface.new('mgmt0')

    interface.switchport_vtp = true
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp is enabled')
    vtp.destroy
  end

  def test_set_switchport_vtp_false_access
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

    interface.switchport_mode = :access
    interface.switchport_vtp = false
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_false_trunk
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

    interface.switchport_mode = :trunk
    interface.switchport_vtp = false
    refute(interface.switchport_vtp,
           'Error: interface, access, vtp not disabled')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_vtp_false_unsupported_mode_disabled
    vtp = Vtp.new(true)
    interface = Interface.new(interfaces[0])

    interface.switchport_mode = :disabled
    interface.switchport_vtp = false
    refute(interface.switchport_vtp,
           'Error: mode :disabled, vtp should be false')
    vtp.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_autostate_disabled_feature_enabled
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
    svi.destroy
  end

  def test_switchport_autostate_disabled_feature_disabled_eth1_1
    interface = Interface.new(interfaces[0])
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_disabled_feature_disabled_mgmt0
    interface = Interface.new('mgmt0')
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
  end

  def test_switchport_autostate_disabled_unsupported_mode
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_autostate_enabled_access
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    config("interface ethernet #{interfaces_id[0]}",
           'switchport',
           'switchport autostate exclude')

    cmd_ref = cmd_ref_switchport_autostate_exclude
    if cmd_ref.config_set?
      assert(interface.switchport_autostate_exclude,
             'Error: interface, access, autostate exclude not enabled')
    else
      assert_equal(interface.default_switchport_autostate_exclude,
                   interface.switchport_autostate_exclude,
                   'Error: interface, access, autostate exclude not disabled')
    end

    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_autostate_disabled_access
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
    svi.destroy
  end

  def test_switchport_autostate_enabled_trunk
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :trunk
    config("interface ethernet #{interfaces_id[0]}",
           'switchport autostate exclude')

    cmd_ref = cmd_ref_switchport_autostate_exclude
    if cmd_ref.config_set?
      assert(interface.switchport_autostate_exclude,
             'Error: interface, access, autostate exclude not enabled')
    else
      assert_equal(interface.default_switchport_autostate_exclude,
                   interface.switchport_autostate_exclude,
                   'Error: interface, access, autostate exclude not disabled')
    end

    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_switchport_autostate_disabled_trunk
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :trunk
    config("interface ethernet #{interfaces_id[0]}",
           'no switchport autostate exclude')

    refute(interface.switchport_autostate_exclude,
           'Error: interface, access, autostate exclude not disabled')
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_raise_error_switchport_not_enabled
    interface = Interface.new(interfaces[0])

    config("interface #{interfaces[0]}", 'no switchport')

    assert_raises(RuntimeError) do
      interface.switchport_autostate_exclude = true
    end
  end

  def test_set_switchport_autostate_default_access
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])

    # switchport must be enabled to configure autostate
    config("interface #{interfaces[0]}", 'switchport')

    result = interface.default_switchport_autostate_exclude
    assert_result(result,
                  'Error: interface, access, autostate exclude not disabled') do
      interface.switchport_autostate_exclude = result
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_autostate_default_trunk
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :trunk

    # switchport must be enabled to configure autostate
    config("interface #{interfaces[0]}", 'switchport')

    result = false
    assert_result(result,
                  'Error: interface, access, autostate exclude not disabled') do
      interface.switchport_autostate_exclude = result
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_autostate_true_access
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])

    # switchport must be enabled to configure autostate
    config("interface #{interfaces[0]}", 'switchport')

    result = true
    assert_result(result,
                  'Error: interface, access, autostate exclude not disabled') do
      interface.switchport_autostate_exclude = result
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_autostate_true_trunk
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :trunk

    # switchport must be enabled to configure autostate
    config("interface #{interfaces[0]}", 'switchport')

    result = true
    assert_result(result,
                  'Error: interface, access, autostate exclude not disabled') do
      interface.switchport_autostate_exclude = result
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_autostate_true_unsupported_mode_disabled
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled

    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = true
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_autostate_true_unsupported_mgmt0
    svi = Interface.new('Vlan23')
    interface = Interface.new('mgmt0')
    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = true
    end
    svi.destroy
  end

  def test_set_switchport_autostate_false_access
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])

    # switchport must be enabled to configure autostate
    config("interface #{interfaces[0]}", 'switchport')

    result = false
    assert_result(result,
                  'Error: interface, access, autostate exclude not disabled') do
      interface.switchport_autostate_exclude = result
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_autostate_false_trunk
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :trunk

    # switchport must be enabled to configure autostate
    config("interface #{interfaces[0]}", 'switchport')

    result = false
    assert_result(result,
                  'Error: interface, access, autostate exclude not disabled') do
      interface.switchport_autostate_exclude = result
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_set_switchport_autostate_false_unsupported_mode_disabled
    svi = Interface.new('Vlan23')
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled

    assert_raises RuntimeError do
      interface.switchport_autostate_exclude = false
    end
    svi.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_mode_invalid
    interface = Interface.new(interfaces[0])
    assert_raises(ArgumentError) { interface.switchport_mode = :unknown }
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_mode_not_supported
    interface = Interface.new('mgmt0')
    assert_raises(RuntimeError) { interface.switchport_mode = :access }
    begin
      interface.switchport_mode = :access
    rescue RuntimeError => e
      msg = '[mgmt0] switchport_mode is not supported on this interface'
      assert_equal(msg, e.message)
    end
  end

  def test_interface_switchport_mode_valid
    switchport_modes = [
      :unknown,
      :disabled,
      :access,
      :trunk,
      #:fex_fabric, (fex is tested by test_interface_switchport_mode_valid_fex)
      :tunnel,
    ]

    interface = Interface.new(interfaces[0])

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
        rescue RuntimeError => e
          msg = "[#{interfaces[0]}] switchport_mode is not supported " \
                'on this interface'
          assert_equal(msg.downcase, e.message)
        end
      end
    end
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_mode_valid_fex
    switchport_modes = [
      :unknown,
      :fex_fabric,
    ]

    interface = Interface.new(interfaces[0])
    switchport_modes.each do |start|
      switchport_modes.each do |finish|
        next if start == :unknown || finish == :unknown
        begin
          # puts "#{start},#{finish}"
          interface.switchport_mode = start
          assert_equal(start, interface.switchport_mode,
                       "Error: Switchport mode, #{start}, not as expected")
          interface.switchport_mode = finish
          assert_equal(finish, interface.switchport_mode,
                       "Error: Switchport mode, #{finish}, not as expected")
        rescue RuntimeError => e
          msg = "[#{interfaces[0]}] switchport_mode is not supported " \
                'on this interface'
          assert_equal(msg.downcase, e.message)
        end
      end
    end
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_allowed_vlan_all
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_allowed_vlan = 'all'
    assert_equal(
      DEFAULT_IF_SWITCHPORT_ALLOWED_VLAN,
      interface.switchport_trunk_allowed_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_allowed_vlan_change
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_allowed_vlan = '20'
    assert_equal('20', interface.switchport_trunk_allowed_vlan)
    interface.switchport_trunk_allowed_vlan = '30'
    assert_equal('30', interface.switchport_trunk_allowed_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_allowed_vlan_default
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_allowed_vlan =
      interface.default_switchport_trunk_allowed_vlan
    assert_equal(
      DEFAULT_IF_SWITCHPORT_ALLOWED_VLAN,
      interface.switchport_trunk_allowed_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_allowed_vlan_invalid
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    assert_raises(RuntimeError) do
      interface.switchport_trunk_allowed_vlan = 'hello'
    end
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_allowed_vlan_none
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_allowed_vlan = 'none'
    assert_equal('none', interface.switchport_trunk_allowed_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_allowed_vlan_valid
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_allowed_vlan = '20, 30'
    assert_equal('20,30', interface.switchport_trunk_allowed_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_native_vlan_change
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_native_vlan = 20
    assert_equal(20, interface.switchport_trunk_native_vlan)
    interface.switchport_trunk_native_vlan = 30
    assert_equal(30, interface.switchport_trunk_native_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_native_vlan_default
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_native_vlan =
      interface.default_switchport_trunk_native_vlan
    assert_equal(
      DEFAULT_IF_SWITCHPORT_NATIVE_VLAN,
      interface.switchport_trunk_native_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_native_vlan_invalid
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    assert_raises(RuntimeError) do
      interface.switchport_trunk_native_vlan = '20, 30'
    end
    interface_ethernet_default(interfaces_id[0])
  end

  def test_interface_switchport_trunk_native_vlan_valid
    interface = Interface.new(interfaces[0])
    interface.switchport_enable
    interface.switchport_trunk_native_vlan = 20
    assert_equal(20, interface.switchport_trunk_native_vlan)
    interface_ethernet_default(interfaces_id[0])
  end

  # TODO: Run this test at your peril as it can cause timeouts for this test and
  # others - 'no feature-set fex' states:
  # "Feature-set Operation may take up to 30 minutes depending on the
  #  size of configuration."
  #
  #   def test_interface_switchport_fex_feature
  #     test_matrix = {
  #       #    [ <set_state>,  <expected> ]
  #       1 => [:uninstalled, :uninstalled], # noop
  #       2 => [:installed,   :installed],
  #       3 => [:uninstalled, :uninstalled],
  #       4 => [:enabled,     :enabled],
  #       5 => [:enabled,     :enabled],     # noop
  #       6 => [:installed,   :enabled],     # noop
  #       7 => [:uninstalled, :uninstalled],
  #       8 => [:disabled,    :uninstalled], # noop
  #       9 => [:installed,   :installed],
  #       10 => [:installed,   :installed],  # noop
  #       11 => [:enabled,     :enabled],
  #       12 => [:disabled,    :disabled],
  #       13 => [:uninstalled, :uninstalled],
  #       14 => [:installed,   :installed],
  #       15 => [:disabled,    :installed],  # noop
  #       16 => [:uninstalled, :uninstalled],
  #     }
  #     interface = Interface.new(interfaces[0])
  #     # start test from :uninstalled state
  #     interface.fex_feature_set(:uninstalled)
  #     from = interface.fex_feature
  #     test_matrix.each do |id,test|
  #       #puts "Test #{id}: #{test}, (from: #{from}"
  #       set_state, expected = test
  #       interface.fex_feature_set(set_state)
  #       curr = interface.fex_feature
  #       assert_equal(expected, curr,
  #                    "Error: fex test #{id}: from #{from} to #{set_state}")
  #       from = curr
  #     end
  #   end

  def test_system_default_switchport_on_off
    interface = Interface.new(interfaces[0])

    system_default_switchport('')
    assert(interface.system_default_switchport,
           'Test for enabled - failed')

    # common default is "no switch"
    system_default_switchport('no ')
    refute(interface.system_default_switchport,
           'Test for disabled - failed')
  rescue RuntimeError => e
    skip('NX-OS defect: system default switchport nvgens twice') if
      e.message[/Expected zero.one value/]
    flunk(e.message)
  end

  def test_system_default_switchport_shutdown_on_off
    interface = Interface.new(interfaces[0])

    system_default_switchport_shutdown('no ')
    refute(interface.system_default_switchport_shutdown,
           'Test for disabled - failed')

    # common default is "shutdown"
    system_default_switchport_shutdown('')
    assert(interface.system_default_switchport_shutdown,
           'Test for enabled - failed')
  end

  def test_interface_svi_command_on_non_vlan
    interface = Interface.new(interfaces[0])
    assert_raises(RuntimeError) { interface.svi_autostate = true }
    assert_raises(RuntimeError) { interface.svi_management = true }
    interface_ethernet_default(interfaces_id[0])
  end
end
