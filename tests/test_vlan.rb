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
  @@cleaned = false # rubocop:disable Style/ClassVars
  def cleanup
    Vlan.vlans.each do |vlan, obj|
      # skip reserved vlans
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      obj.destroy
    end
    interface_ethernet_default(interfaces[0])
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

  def test_vlan_collection_not_empty
    vlans = Vlan.vlans
    assert_equal(false, vlans.empty?, 'VLAN collection is empty')
    assert(vlans.key?('1'), 'VLAN 1 does not exist')
  end

  def test_vlan_create_invalid
    e = assert_raises(CliError) { Vlan.new(5000) }
    assert_match(/Invalid value.range/, e.message)
  end

  def test_vlan_create_invalid_non_numeric_vlan
    e = assert_raises(ArgumentError) { Vlan.new('fred') }
    assert_match(/Invalid value.non-numeric/, e.message)
  end

  def test_vlan_create_and_destroy
    v = Vlan.new(1000)
    vlans = Vlan.vlans
    assert(vlans.key?('1000'), 'Error: failed to create vlan 1000')

    v.destroy
    vlans = Vlan.vlans
    refute(vlans.key?('1000'), 'Error: failed to destroy vlan 1000')
  end

  def test_vlan_name_default_1000
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

  def test_vlan_name_default_40
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

  def test_vlan_name_nil
    v = Vlan.new(1000)
    assert_raises(TypeError) do
      v.vlan_name = nil
    end
    v.destroy
  end

  def test_vlan_name_invalid
    v = Vlan.new(1000)
    assert_raises(TypeError) do
      v.vlan_name = Cisco::Node.instance
    end
    v.destroy
  end

  def test_vlan_name_zero_length
    v = Vlan.new(1000)
    v.vlan_name = ''
    assert('', v.vlan_name)
    v.destroy
  end

  def test_vlan_name_length_valid
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

  def test_vlan_name_too_long
    v = Vlan.new(1000)
    name = 'a' * VLAN_NAME_SIZE
    assert_raises(RuntimeError, 'vlan misconfig did not raise RuntimeError') do
      v.vlan_name = name
    end
    ref = cmd_ref.lookup('vlan', 'name')
    assert(ref, 'Error, reference not found for vlan name')
    v.destroy
  end

  def test_vlan_name_duplicate
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

  def test_vlan_state_invalid
    v = Vlan.new(1000)
    assert_raises(RuntimeError) do
      v.state = 'unknown'
    end
    v.destroy
  end

  def test_vlan_state_valid
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

  def test_vlan_shutdown_extended
    v = Vlan.new(2000)
    assert_raises(RuntimeError, 'vlan misconfig did not raise RuntimeError') do
      v.shutdown = 'shutdown'
    end
    v.destroy
  end

  def test_vlan_shutdown_valid
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

  def test_vlan_add_remove_interface_valid
    v = Vlan.new(1000)
    interfaces = Interface.interfaces
    interfaces_added_to_vlan = []
    count = 3
    interfaces.each do |name, interface|
      next unless interface.name.match(%r{ethernet[0-9/]+$}) && count > 0
      interface_ethernet_default(%r{net(\d+/\d+)}.match(name)[1])
      interfaces_added_to_vlan << name
      interface.switchport_mode = :access
      v.add_interface(interface)
      count -= 1
    end
    assert_equal(0, count)

    interfaces = v.interfaces
    interfaces.each do |name, interface|
      assert_includes(interfaces_added_to_vlan, name)
      assert_equal(v.vlan_id, interface.access_vlan, 'Interface.access_vlan')
      v.remove_interface(interface)
    end

    interfaces = v.interfaces
    assert(interfaces.empty?)
    v.destroy
  end

  def test_vlan_add_interface_invalid
    v = Vlan.new(1000)
    interface = Interface.new(interfaces[0])
    begin
      interface.switchport_mode = :disabled
      assert_raises(RuntimeError) { v.add_interface(interface) }
      v.destroy
    end
  rescue RuntimeError => e
    linecard_cfg_change_not_allowed?(e)
  end

  def test_vlan_remove_interface_invalid
    v = Vlan.new(1000)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :access
    v.add_interface(interface)
    begin
      interface.switchport_mode = :disabled
      assert_raises(RuntimeError) { v.remove_interface(interface) }
      v.destroy
    end
  rescue RuntimeError => e
    linecard_cfg_change_not_allowed?(e)
  end

  def test_vlan_mapped_vnis
    # Map
    skip('Feature vn-segment-vlan-based is not supported on this platform.') if
      node.product_id =~ /N3K-C3048/
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
  end
end
