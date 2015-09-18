# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

# TestSvi - Minitest for Interface configuration of SVI interfaces.
class TestSvi < CiscoTestCase
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

  def system_default_svi_autostate(state='')
    @device.cmd('configure terminal')
    @device.cmd("#{state}system default interface-vlan autostate")
    @device.cmd('end')
    node.cache_flush
  end

  def test_svi_prop_nil_when_ethernet
    intf = Interface.new(interfaces[0])
    assert_nil(intf.svi_autostate,
               'Error: svi_autostate should be nil when interface is ethernet')
    assert_nil(intf.svi_management,
               'Error: svi_management should be nil when interface is ethernet')
  end

  def test_svi_create_valid
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

  def test_svi_create_vlan_invalid
    assert_raises(CliError) { Interface.new('10.1.1.1') }
  end

  def test_svi_create_vlan_invalid_value
    assert_raises(CliError) { Interface.new('Vlan0') }
  end

  def test_svi_create_vlan_nil
    assert_raises(TypeError) { Interface.new(nil) }
  end

  def test_svi_name
    svi = Interface.new('Vlan23')
    assert_equal('vlan23', svi.name, 'Error: svi vlan name is wrong')
    svi.destroy
  end

  def test_svi_assignment
    svi = Interface.new('Vlan23')
    svi.svi_management = true
    assert(svi.svi_management, 'Error: svi svi_management, false')
    svi_extra = svi
    assert(svi_extra.svi_management, 'Error: new svi svi_management, false')
    svi.destroy
  end

  def test_svi_get_autostate_false
    svi = Interface.new('Vlan23')

    @device.cmd('configure terminal')
    @device.cmd('interface vlan 23')
    @device.cmd('no autostate')
    @device.cmd('end')
    # Flush the cache since we've modified the device
    node.cache_flush
    ref = cmd_ref_autostate
    result = ref.default_value
    result = false if ref.config_set
    assert_equal(result, svi.svi_autostate,
                 'Error: svi autostate not correct.')
    svi.destroy
  end

  def test_svi_get_autostate_true
    svi = Interface.new('Vlan23')

    @device.cmd('configure terminal')
    @device.cmd('interface vlan 23')
    @device.cmd('autostate')
    @device.cmd('end')
    # Flush the cache since we've modified the device
    node.cache_flush

    ref = cmd_ref_autostate
    result = ref.default_value
    result = true if ref.config_set
    assert_equal(result, svi.svi_autostate,
                 'Error: svi autostate not correct.')
    svi.destroy
  end

  def test_svi_set_autostate_false
    ref = cmd_ref_autostate
    svi = Interface.new('Vlan23')
    assert_result(ref.test_config_result(false),
                  'Error: svi autostate not set to false') do
      svi.svi_autostate = false
    end
    svi.destroy
  end

  def test_svi_set_autostate_true
    svi = Interface.new('Vlan23')
    ref = cmd_ref_autostate
    assert_result(ref.test_config_result(true),
                  'Error: svi autostate not set to true') do
      svi.svi_autostate = true
    end
    svi.destroy
  end

  def test_svi_set_autostate_default
    svi = Interface.new('Vlan23')
    ref = cmd_ref_autostate
    default_value = ref.default_value
    assert_result(ref.test_config_result(default_value),
                  'Error: svi autostate not set to default') do
      svi.svi_autostate = default_value
    end
    svi.destroy
  end

  def test_svi_get_management_true
    svi = Interface.new('Vlan23')

    @device.cmd('configure terminal')
    @device.cmd('interface vlan 23')
    @device.cmd('management')
    @device.cmd('end')
    # Flush the cache since we've modified the device
    node.cache_flush

    assert(svi.svi_management)
    svi.destroy
  end

  def test_svi_set_management_false
    svi = Interface.new('Vlan23')
    svi.svi_management = false
    refute(svi.svi_management)
    svi.destroy
  end

  def test_svi_set_management_true
    svi = Interface.new('Vlan23')
    svi.svi_management = true
    assert(svi.svi_management)
    svi.destroy
  end

  def test_svi_set_management_default
    svi = Interface.new('Vlan23')
    svi.svi_management = true
    assert(svi.svi_management)

    svi.svi_management = svi.default_svi_management
    assert_equal(svi.default_svi_management, svi.svi_management)
    svi.destroy
  end

  def test_svi_get_svis
    count = 5

    ref = cmd_ref_autostate
    # Have to account for interface Vlan1 why we add 1 to count
    (2..count + 1).each do |i|
      str = 'Vlan' + i.to_s
      svi = Interface.new(str)
      assert_result(ref.test_config_result(false),
                    'Error: svi autostate not set to false') do
        svi.svi_autostate = false
      end
      svi.svi_management = true
    end

    svis = Interface.interfaces
    ref = cmd_ref_autostate
    result = ref.default_value
    svis.each do |id, svi|
      case id
      when /^vlan1$/
        result = true if ref.config_set
        assert_equal(result, svi.svi_autostate,
                     'Error: svis collection, Vlan1, incorrect autostate')
        refute(svi.svi_management,
               'Error: svis collection, Vlan1, incorrect management')
      when /^vlan/
        result = false if ref.config_set
        assert_equal(result, svi.svi_autostate,
                     "Error: svis collection, Vlan#{id}, incorrect autostate")
        assert(svi.svi_management,
               "Error: svis collection, Vlan#{id}, incorrect management")
      end
    end

    svis.each_key do |id|
      @device.cmd("conf t ; no interface #{id} ; end") if id[/^vlan/]
    end
  end

  def test_svi_create_interface_description
    svi = Interface.new('Vlan23')

    description = 'Test description'
    svi.description = description
    assert_equal(description, svi.description,
                 'Error: Description not configured')
    svi.destroy
  end

  def test_system_default_svi_autostate_on_off
    interface = Interface.new('Eth1/1')

    system_default_svi_autostate('no ')
    refute(interface.system_default_svi_autostate,
           'Test for disabled - failed')

    # common default is enabled
    system_default_svi_autostate('')
    assert(interface.system_default_svi_autostate,
           'Test for enabled - failed')
  end
end
