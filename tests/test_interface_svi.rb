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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/interface'

include Cisco

# TestSvi - Minitest for Interface configuration of SVI interfaces.
class TestSvi < CiscoTestCase
  def system_default_svi_autostate(state='')
    s = config("#{state}system default interface-vlan autostate")
    if s[/Invalid input/] # rubocop:disable Style/GuardClause
      skip("'system default interface-vlan autostate' is not supported")
    end
  end

  def test_prop_nil_when_ethernet
    intf = Interface.new(interfaces[0])
    assert_nil(intf.svi_autostate,
               'Error: svi_autostate should be nil when interface is ethernet')
    assert_nil(intf.svi_management,
               'Error: svi_management should be nil when interface is ethernet')
  end

  def test_create_valid
    svi = Interface.new('Vlan23')
    @default_show_command = 'show run interface all | inc Vlan'
    assert_show_match(pattern: /interface Vlan1/,
                      msg:     'Error: Failed to create svi Vlan1')

    assert_show_match(pattern: /interface Vlan23/,
                      msg:     'Error: Failed to create svi Vlan23')

    svi.destroy

    # Verify that svi23 got removed now that we invoked svi.destroy
    refute_show_match(pattern: /interface Vlan23/,
                      msg:     'Error: svi Vlan23 still configured')
  end

  def test_create_invalid
    assert_raises(CliError) { Interface.new('10.1.1.1') }
    assert_raises(CliError, Cisco::UnsupportedError) { Interface.new('Vlan0') }
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
    svi_extra = Interface.new('Vlan23')
    assert(svi_extra.svi_management, 'Error: new svi svi_management, false')
    svi.destroy
  end

  def test_get_autostate
    svi = Interface.new('Vlan23')

    config('interface vlan 23', 'no autostate')
    refute(svi.svi_autostate, 'Error: svi autostate not correct.')

    config('interface vlan 23', 'autostate')
    assert(svi.svi_autostate, 'Error: svi autostate not correct.')
    svi.destroy
  end

  def test_set_autostate
    svi = Interface.new('Vlan23')
    svi.svi_autostate = false
    refute(svi.svi_autostate, 'Error: svi autostate not set to false')

    svi.svi_autostate = true
    assert(svi.svi_autostate, 'Error: svi autostate not set to true')

    svi.svi_autostate = svi.default_svi_autostate
    assert_equal(svi.default_svi_autostate, svi.svi_autostate,
                 'Error: svi autostate not set to default')
    svi.destroy
  end

  def test_get_management
    svi = Interface.new('Vlan23')

    config('interface vlan 23', 'management')

    assert(svi.svi_management)
    svi.destroy
  end

  def test_set_management
    svi = Interface.new('Vlan23')
    svi.svi_management = false
    refute(svi.svi_management)

    svi.svi_management = true
    assert(svi.svi_management)

    svi.svi_management = true
    assert(svi.svi_management)

    svi.svi_management = svi.default_svi_management
    assert_equal(svi.default_svi_management, svi.svi_management)
    svi.destroy
  end

  def test_get_svis
    count = 5

    # Have to account for interface Vlan1 why we add 1 to count
    (2..count + 1).each do |i|
      str = 'Vlan' + i.to_s
      svi = Interface.new(str)
      svi.svi_autostate = false
      refute(svi.svi_autostate, 'Error: svi autostate not set to false')
      svi.svi_management = true
    end

    svis = Interface.interfaces
    svis.each do |id, svi|
      case id
      when /^vlan1$/
        assert_equal(svi.default_svi_autostate, svi.svi_autostate,
                     'Error: svis collection, Vlan1, incorrect autostate')
        refute(svi.svi_management,
               'Error: svis collection, Vlan1, incorrect management')
      when /^vlan/
        refute(svi.svi_autostate,
               "Error: svis collection, #{id}, incorrect autostate")
        assert(svi.svi_management,
               "Error: svis collection, #{id}, incorrect management")
      end
    end

    svis.each_key do |id|
      config("no interface #{id}") if id[/^vlan/]
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
