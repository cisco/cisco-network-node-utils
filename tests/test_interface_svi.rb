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
  attr_reader :svi

  def self.runnable_methods
    # We don't have a separate YAML file to key off, so we check platform
    return super unless platform == :ios_xr
    remove_method :setup
    remove_method :teardown
    [:xr_unsupported]
  end

  def xr_unsupported
    skip("Skipping #{self.class}; Vlan interfaces are not supported on IOS XR")
  end

  def setup
    super
    remove_all_svis if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
    @svi = Interface.new('Vlan23')
  end

  def remove_all_svis
    Interface.interfaces.each do |int, obj|
      next unless int[/vlan/]
      next if int[/vlan1/]
      obj.destroy
    end
  end

  def teardown
    remove_all_svis
    config_no_warn('no feature private-vlan')
    super
  end

  def skip_autostate_test?
    skip('svi autostate properties are not supported on this platform') if
      node.product_id =~ /N(5|6)K/
  end

  def system_default_svi_autostate(state='')
    s = config("#{state}system default interface-vlan autostate")
    if s[/Invalid input/] # rubocop:disable Style/GuardClause
      skip("'system default interface-vlan autostate' is not supported")
    end
  end

  def test_prop_nil_when_eth
    skip_autostate_test?
    intf = Interface.new(interfaces[0])
    assert_nil(intf.svi_autostate,
               'Error: svi_autostate should be nil when interface is ethernet')
    assert_nil(intf.svi_management,
               'Error: svi_management should be nil when interface is ethernet')
  end

  def test_create_valid
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
  end

  def test_create_vlan_nil
    assert_raises(TypeError) { Interface.new(nil) }
  end

  def test_name
    assert_equal('vlan23', svi.name, 'Error: svi vlan name is wrong')
  end

  def test_assignment
    svi.svi_management = true
    assert(svi.svi_management, 'Error: svi svi_management, false')
    svi_extra = Interface.new('Vlan23')
    assert(svi_extra.svi_management, 'Error: new svi svi_management, false')
  end

  def test_get_autostate
    # TBD: autostate is also tested in test_interface_switchport.rb so remove
    # tests from one or the other
    skip_autostate_test?

    config('interface vlan 23', 'no autostate')
    refute(svi.svi_autostate, 'Error: svi autostate not correct.')

    config('interface vlan 23', 'autostate')
    assert(svi.svi_autostate, 'Error: svi autostate not correct.')
  end

  def test_set_autostate
    skip_autostate_test?
    svi.svi_autostate = false
    refute(svi.svi_autostate, 'Error: svi autostate not set to false')

    svi.svi_autostate = true
    assert(svi.svi_autostate, 'Error: svi autostate not set to true')

    svi.svi_autostate = svi.default_svi_autostate
    assert_equal(svi.default_svi_autostate, svi.svi_autostate,
                 'Error: svi autostate not set to default')
  end

  def test_get_management
    config('interface vlan 23', 'management')

    assert(svi.svi_management)
  end

  def test_set_management
    svi.svi_management = false
    refute(svi.svi_management)

    svi.svi_management = true
    assert(svi.svi_management)

    svi.svi_management = svi.default_svi_management
    assert_equal(svi.default_svi_management, svi.svi_management)
  end

  def config_svi_properties(state)
    # We don't want the default vlan23 for this test:
    svi.destroy
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

  def test_description
    description = 'Test description'
    svi.description = description
    assert_equal(description, svi.description,
                 'Error: Description not configured')
  end

  def test_sys_def_svi_autostate
    skip_autostate_test?
    skip_legacy_defect?('8.0.1', 'CSC: Atherton behavior change')
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
