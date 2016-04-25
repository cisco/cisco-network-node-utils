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
require_relative '../lib/cisco_node_utils/vlan'
require_relative '../lib/cisco_node_utils/interface'

include Cisco

# TestVlan - Minitest for Vlan node utility
class TestVlan < CiscoTestCase
  @skip_unless_supported = 'vlan'

  @@cleaned = false # rubocop:disable Style/ClassVars
  def cleanup
    Vlan.vlans.each do |vlan, obj|
      # skip reserved vlans
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      obj.destroy
    end
    interface_ethernet_default(interfaces[0])
    config_no_warn('no feature vtp')
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
  end

  def interface_ethernet_default(intf)
    config("default interface #{intf}")
  end

  def linecard_cfg_change_not_allowed?(e)
    skip('Linecard does not support this test') if
      e.message[/requested config change not allowed/]
    flunk(e.message)
  end

  def test_collection_not_empty
    vlans = Vlan.vlans
    assert_equal(false, vlans.empty?, 'VLAN collection is empty')
    assert(vlans.key?('1'), 'VLAN 1 does not exist')
  end

  def test_create_invalid
    e = assert_raises(CliError) { Vlan.new(5000) }
    assert_match(/Invalid value.range/, e.message)
  end

  def test_create_invalid_non_numeric_vlan
    e = assert_raises(ArgumentError) { Vlan.new('fred') }
    assert_match(/Invalid value.non-numeric/, e.message)
  end

  def test_create_and_destroy
    v = Vlan.new(1000)
    vlans = Vlan.vlans
    assert(vlans.key?('1000'), 'Error: failed to create vlan 1000')

    v.destroy
    vlans = Vlan.vlans
    refute(vlans.key?('1000'), 'Error: failed to destroy vlan 1000')
  end

  def test_name_default_1000
    v = Vlan.new(1000)
    assert_equal(v.default_vlan_name, v.vlan_name,
                 'Error: Vlan name not initialized to default')

    name = 'Uplink-Chicago'
    v.vlan_name = name
    assert_equal(name, v.vlan_name, "Error: Vlan name not updated to #{name}")

    v.vlan_name = v.default_vlan_name
    assert_equal(v.default_vlan_name, v.vlan_name,
                 'Error: Vlan name not restored to default')
    v.destroy
  end

  def test_name_default_40
    v = Vlan.new(40)
    assert_equal(v.default_vlan_name, v.vlan_name,
                 'Error: Vlan name not initialized to default')

    name = 'Uplink-Chicago'
    v.vlan_name = name
    assert_equal(name, v.vlan_name, "Error: Vlan name not updated to #{name}")

    v.vlan_name = v.default_vlan_name
    assert_equal(v.default_vlan_name, v.vlan_name,
                 'Error: Vlan name not restored to default')
    v.destroy
  end

  def test_name_nil
    v = Vlan.new(1000)
    assert_raises(TypeError) do
      v.vlan_name = nil
    end
    v.destroy
  end

  def test_name_invalid
    v = Vlan.new(1000)
    assert_raises(TypeError) do
      v.vlan_name = Cisco::Node.instance
    end
    v.destroy
  end

  def test_name_zero_length
    v = Vlan.new(1000)
    v.vlan_name = ''
    assert('', v.vlan_name)
    v.destroy
  end

  def test_name_length_valid
    v = Vlan.new(1000)
    alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'
    name = ''
    1.upto(VLAN_NAME_SIZE - 1) do |i|
      begin
        name += alphabet[i % alphabet.size, 1]
        if i == VLAN_NAME_SIZE - 1
          v.vlan_name = name
          assert_equal(name, v.vlan_name)
        end
      end
    end
    v.destroy
  end

  def test_name_too_long
    v = Vlan.new(1000)
    name = 'a' * VLAN_NAME_SIZE
    assert_raises(RuntimeError, 'vlan misconfig did not raise RuntimeError') do
      v.vlan_name = name
    end
    ref = cmd_ref.lookup('vlan', 'name')
    assert(ref, 'Error, reference not found for vlan name')
    v.destroy
  end

  def test_name_duplicate
    # Testbed cleanup
    v = Vlan.new(1000)
    v.destroy
    v = Vlan.new(1001)
    v.destroy
    # start test
    v1 = Vlan.new(1000)
    v1.vlan_name = 'test'
    v2 = Vlan.new(1001)
    assert_raises(RuntimeError, 'vlan misconfig did not raise RuntimeError') do
      v2.vlan_name = 'test'
    end
    v1.destroy
    v2.destroy
  end

  def test_state_invalid
    v = Vlan.new(1000)
    assert_raises(CliError) do
      v.state = 'unknown'
    end
    v.destroy
  end

  def test_state_valid
    states = %w(unknown active suspend)
    v = Vlan.new(1000)
    states.each do |start|
      states.each do |finish|
        next if start == 'unknown' || finish == 'unknown'
        v.state = start
        assert_equal(start, v.state, 'start')
        v.state = finish
        assert_equal(finish, v.state, 'finish')
      end
    end
    v.destroy
  end

  def test_shutdown_extended
    v = Vlan.new(2000)
    assert_raises(RuntimeError, 'vlan misconfig did not raise RuntimeError') do
      v.shutdown = 'shutdown'
    end
    v.destroy
  end

  def test_shutdown_valid
    shutdown_states = [true, false]
    v = Vlan.new(1000)
    shutdown_states.each do |start|
      shutdown_states.each do |finish|
        v.shutdown = start
        assert_equal(start, v.shutdown, 'start')
        v.shutdown = finish
        assert_equal(finish, v.shutdown, 'finish')
      end
    end
    v.destroy
  end

  def test_add_remove_interface
    vlan_id = 1000
    v = Vlan.new(vlan_id)

    # Remove vlan_id from all interfaces currently using it
    v.interfaces.each do |_name, i|
      v.remove_interface(i)
    end
    assert_empty(v.interfaces, "access vlan #{vlan_id} should not be "\
                               'present on any interfaces')

    # Add test vlan to 3 ethernet interfaces
    vlan_intf_max = 3
    vlan_intf_list = []
    Interface.interfaces.each do |name, i|
      next unless i.name[/ethernet/]
      interface_ethernet_default(name)
      i.switchport_mode = :access
      assert_equal(i.default_access_vlan, i.access_vlan,
                   "access vlan is not default on #{name}")

      v.add_interface(i)
      assert_equal(vlan_id, i.access_vlan,
                   "access vlan #{vlan_id} not present on #{name}")
      vlan_intf_list << name
      break if vlan_intf_list.count == vlan_intf_max
    end
    count = v.interfaces.count
    assert_equal(vlan_intf_max, count,
                 "vlan #{vlan_id} found on #{count} interfaces, "\
                 "expected #{vlan_intf_max} total")

    # Remove test vlan from interfaces
    vlan_intf_list.each do |name|
      i = Interface.new(name)
      v.remove_interface(i)
      assert_equal(i.default_access_vlan, i.access_vlan,
                   "access vlan #{vlan_id} should not be present on #{name}")
    end
    assert_empty(v.interfaces, "access vlan #{vlan_id} should not be "\
                               'present on any interfaces')
    v.destroy
  end

  def test_add_interface_invalid
    v = Vlan.new(1000)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    assert_raises(CliError) { v.add_interface(interface) }
    v.destroy
  rescue RuntimeError => e
    linecard_cfg_change_not_allowed?(e)
  end

  def test_remove_interface_invalid
    v = Vlan.new(1000)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :access
    v.add_interface(interface)
    interface.switchport_mode = :disabled
    assert_raises(CliError) { v.remove_interface(interface) }

    v.destroy
  rescue RuntimeError => e
    linecard_cfg_change_not_allowed?(e)
  end

  def test_mapped_vnis
    # Map
    v1 = Vlan.new(100)
    vni1 = 10_000
    v1.mapped_vni = vni1
    assert_equal(vni1, v1.mapped_vni)

    v2 = Vlan.new(500)
    vni2 = 50_000
    v2.mapped_vni = vni2
    assert_equal(vni2, v2.mapped_vni)

    v3 = Vlan.new(900)
    vni3 = 90_000
    v3.mapped_vni = vni3
    assert_equal(vni3, v3.mapped_vni)
    # Unmap
    v1.mapped_vni = v1.default_mapped_vni
    assert_equal(v1.default_mapped_vni, v1.mapped_vni)

    v2.mapped_vni = v2.default_mapped_vni
    assert_equal(v2.default_mapped_vni, v2.mapped_vni)

    v3.mapped_vni = v3.default_mapped_vni
    assert_equal(v3.default_mapped_vni, v3.mapped_vni)
  rescue RuntimeError => e
    hardware_supports_feature?(e.message)
  end

  def test_another_vlan_as_fabric_control
    if validate_property_excluded?('vlan', 'fabric_control')
      assert_raises(Cisco::UnsupportedError) do
        Vlan.new('100').fabric_control = true
      end
      return
    end

    vlan = Vlan.new('100')
    assert_equal(vlan.default_fabric_control, vlan.fabric_control,
                 'Error: Vlan fabric-control is not matching')
    vlan.fabric_control = true
    assert(vlan.fabric_control)
    another_vlan = Vlan.new(101)

    assert_raises(RuntimeError,
                  'VLAN misconfig did not raise CliError') do
      another_vlan.fabric_control = true
    end
    vlan.destroy
    another_vlan.destroy
  end

  def test_mode_with_pvlan
    v = Vlan.new(1000)
    if validate_property_excluded?('vlan', 'private_vlan_type') ||
       validate_property_excluded?('vlan', 'mode')
      features = 'private_vlan_type and/or vlan mode'
      skip("Skip test: Features #{features} are not supported on this device")
    end
    result = 'CE'
    v.private_vlan_type = 'primary'
    assert_equal(result, v.mode)
  end
end
