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

# TestSvi - Minitest for Interface configuration of SVI interfaces.
class TestSvi < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def remove_all_svis
    Interface.interfaces.each do |int, obj|
      next unless int[/vlan/]
      next if int[/vlan1/]
      obj.destroy
    end
  end

  def setup
    super
    remove_all_svis if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    super
    remove_all_svis
  end

  def cmd_ref_autostate
    ref = cmd_ref.lookup('interface', 'svi_autostate')
    assert(ref, 'Error, reference not found for autostate')
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

  def skip_autostate_test?
    skip('svi autostate properties are not supported on this platform') if
      node.product_id =~ /N(5|6)K/
  end

  def system_default_svi_autostate(state='')
    config("#{state}system default interface-vlan autostate")
  end

  def test_prop_nil_when_ethernet
    skip_autostate_test?
    intf = Interface.new(interfaces[0])
    assert_nil(intf.svi_autostate,
               'Error: svi_autostate should be nil when interface is ethernet')
    assert_nil(intf.svi_management,
               'Error: svi_management should be nil when interface is ethernet')
  end

  def test_create_valid
    svi = Interface.new('Vlan23')
    s = @device.cmd('show run interface all | inc Vlan')
    cmd = 'interface Vlan1'
    assert(s.include?(cmd), 'Error: Failed to create svi Vlan1')

    cmd = 'interface Vlan23'
    assert(s.include?(cmd), 'Error: Failed to create svi Vlan23')
    svi.destroy

    # Verify that svi23 got removed now that we invoked svi.destroy
    s = @device.cmd('show run interface all | inc Vlan')
    cmd = 'interface Vlan23'
    refute(s.include?(cmd), 'Error: svi Vlan23 still configured')
  end

  def test_create_vlan_invalid
    assert_raises(CliError) { Interface.new('10.1.1.1') }
  end

  def test_create_vlan_invalid_value
    assert_raises(CliError) { Interface.new('Vlan0') }
  end

  def test_create_vlan_nil
    assert_raises(TypeError) { Interface.new(nil) }
  end

  def test_name
    svi = Interface.new('Vlan23')
    assert_equal('vlan23', svi.name, 'Error: svi vlan name is wrong')
    svi.destroy
  end

  def test_assignment
    svi = Interface.new('Vlan23')
    svi.svi_management = true
    assert(svi.svi_management, 'Error: svi svi_management, false')
    svi_extra = svi
    assert(svi_extra.svi_management, 'Error: new svi svi_management, false')
    svi.destroy
  end

  def test_get_autostate_false
    skip_autostate_test?
    svi = Interface.new('Vlan23')

    config('interface vlan 23', 'no autostate')
    refute(svi.svi_autostate, 'Error: svi autostate not correct.')
    svi.destroy
  end

  def test_get_autostate_true
    skip_autostate_test?
    svi = Interface.new('Vlan23')

    config('interface vlan 23', 'autostate')
    assert(svi.svi_autostate, 'Error: svi autostate not correct.')
    svi.destroy
  end

  def test_set_autostate_false
    skip_autostate_test?
    ref = cmd_ref_autostate
    svi = Interface.new('Vlan23')
    assert_result(ref.test_config_result(false),
                  'Error: svi autostate not set to false') do
      svi.svi_autostate = false
    end
    svi.destroy
  end

  def test_set_autostate_true
    skip_autostate_test?
    svi = Interface.new('Vlan23')
    ref = cmd_ref_autostate
    assert_result(ref.test_config_result(true),
                  'Error: svi autostate not set to true') do
      svi.svi_autostate = true
    end
    svi.destroy
  end

  def test_set_autostate_default
    skip_autostate_test?
    svi = Interface.new('Vlan23')
    ref = cmd_ref_autostate
    default_value = ref.default_value
    assert_result(ref.test_config_result(default_value),
                  'Error: svi autostate not set to default') do
      svi.svi_autostate = default_value
    end
    svi.destroy
  end

  def test_get_management_true
    svi = Interface.new('Vlan23')

    config('interface vlan 23', 'management')

    assert(svi.svi_management)
    svi.destroy
  end

  def test_set_management_false
    svi = Interface.new('Vlan23')
    svi.svi_management = false
    refute(svi.svi_management)
    svi.destroy
  end

  def test_set_management_true
    svi = Interface.new('Vlan23')
    svi.svi_management = true
    assert(svi.svi_management)
    svi.destroy
  end

  def test_set_management_default
    svi = Interface.new('Vlan23')
    svi.svi_management = true
    assert(svi.svi_management)

    svi.svi_management = svi.default_svi_management
    assert_equal(svi.default_svi_management, svi.svi_management)
    svi.destroy
  end

  def config_svi_properties(state)
    # Skip default vlan1
    (2..6).each do |i|
      svi = Interface.new('Vlan' + i.to_s)
      svi.svi_autostate = state unless /N(5|6)K/.match(node.product_id)
      svi.svi_management = state
    end
  end

  def test_get_svis
    config_svi_properties(true)
    Interface.interfaces.each do |id, obj|
      next if id[/vlan1/]
      next unless id[/vlan/]
      unless /N(5|6)K/.match(node.product_id)
        assert(obj.svi_autostate, "svi autostate should be enabled #{id}")
      end
      assert(obj.svi_management, "svi management should be enabled #{id}")
    end

    config_svi_properties(false)
    Interface.interfaces.each do |id, obj|
      next if id[/vlan1/]
      next unless id[/vlan/]
      unless /N(5|6)K/.match(node.product_id)
        refute(obj.svi_autostate, "svi autostate should be disabled #{id}")
      end
      refute(obj.svi_management, "svi management should be disabled #{id}")
    end
  end

  def test_create_interface_description
    svi = Interface.new('Vlan23')

    description = 'Test description'
    svi.description = description
    assert_equal(description, svi.description,
                 'Error: Description not configured')
    svi.destroy
  end

  def test_system_default_svi_autostate_on_off
    skip_autostate_test?
    interface = Interface.new(interfaces[0])

    system_default_svi_autostate('no ')
    refute(interface.system_default_svi_autostate,
           'Test for disabled - failed')

    # common default is enabled
    system_default_svi_autostate('')
    assert(interface.system_default_svi_autostate,
           'Test for enabled - failed')
  end
end
