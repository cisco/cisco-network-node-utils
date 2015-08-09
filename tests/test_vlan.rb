# Copyright (c) 2013-2015 Cisco and/or its affiliates.
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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/vlan", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/interface", __FILE__)

include Cisco

class TestVlan < CiscoTestCase
  def interface_ethernet_default(ethernet_id)
    s = @device.cmd("configure terminal")
    s = @device.cmd("default interface ethernet #{ethernet_id}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_vlan_collection_not_empty
    vlans = Vlan.vlans
    assert_equal(false, vlans.empty?(), "VLAN collection is empty")
    assert(vlans.key?("1"), "VLAN 1 does not exist")
  end

  def test_vlan_create_invalid
    e = assert_raises(CliError) do
      v = Vlan.new(5000)
    end
    assert_match(/Invalid value.range/, e.message)
  end

  def test_vlan_create_invalid_non_numeric_vlan
    e = assert_raises(ArgumentError) do
      v = Vlan.new("fred")
    end
    assert_match(/Invalid value.non-numeric/, e.message)
  end

  def test_vlan_create_and_destroy
    v = Vlan.new(1000)
    vlans = Vlan.vlans
    assert(vlans.key?("1000"), "Error: failed to create vlan 1000")

    v.destroy
    vlans = Vlan.vlans
    refute(vlans.key?("1000"), "Error: failed to destroy vlan 1000")
  end

  def test_vlan_name_default_1000
    v = Vlan.new(1000)
    assert_equal(v.default_vlan_name, v.vlan_name,
                 "Error: Vlan name not initialized to default")

    name = "Uplink-Chicago"
    v.vlan_name = name
    assert_equal(name, v.vlan_name, "Error: Vlan name not updated to #{name}")

    v.vlan_name = v.default_vlan_name
    assert_equal(v.default_vlan_name, v.vlan_name,
                 "Error: Vlan name not restored to default")
    v.destroy
  end

  def test_vlan_name_default_40
    v = Vlan.new(40)
    assert_equal(v.default_vlan_name, v.vlan_name,
                 "Error: Vlan name not initialized to default")

    name = "Uplink-Chicago"
    v.vlan_name = name
    assert_equal(name, v.vlan_name, "Error: Vlan name not updated to #{name}")

    v.vlan_name = v.default_vlan_name
    assert_equal(v.default_vlan_name, v.vlan_name,
                 "Error: Vlan name not restored to default")
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
    v.vlan_name = ""
    assert("", v.vlan_name)
    v.destroy
  end

  def test_vlan_name_length_valid
    v = Vlan.new(1000)
    alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
    name = ""
    1.upto(VLAN_NAME_SIZE - 1) { | i |
      begin
        name += alphabet[i % alphabet.size, 1]
        # puts "n is #{name}"
        if i == VLAN_NAME_SIZE - 1
          v.vlan_name = name
          assert_equal(name, v.vlan_name)
        end
      end
    }
    v.destroy
  end

  def test_vlan_name_too_long
    v = Vlan.new(1000)
    name = "a" * VLAN_NAME_SIZE
    assert_raises(RuntimeError, "vlan misconfig did not raise RuntimeError") do
      v.vlan_name = name
    end
    ref = cmd_ref.lookup("vlan", "name")
    assert(ref, "Error, reference not found for vlan name")
    ref = nil
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
    v1.vlan_name = "test"
    v2 = Vlan.new(1001)
    assert_raises(RuntimeError, "vlan misconfig did not raise RuntimeError") do
      v2.vlan_name = "test"
    end
    v1.destroy
    v2.destroy
  end

  def test_vlan_state_extended
    v = Vlan.new(2000)
    v.state = "suspend"
    v.destroy
  end

  def test_vlan_state_invalid
    v = Vlan.new(1000)
    assert_raises(RuntimeError) do
      v.state = "unknown"
    end
    v.destroy
  end

  def test_vlan_state_valid
    states = %w(unknown active suspend)
    v = Vlan.new(1000)
    states.each { | start |
      states.each { | finish |
        if start != "unknown" &&
           finish != "unknown"
          v.state = start
          assert_equal(start, v.state, "start")
          v.state = finish
          assert_equal(finish, v.state, "finish")
        end
      }
    }
    v.destroy
  end

  def test_vlan_shutdown_extended
    v = Vlan.new(2000)
    assert_raises(RuntimeError, "vlan misconfig did not raise RuntimeError") do
      v.shutdown = "shutdown"
    end
    v.destroy
  end

  def test_vlan_shutdown_valid
    shutdown_states = [
      true,
      false
    ]
    v = Vlan.new(1000)
    shutdown_states.each { | start |
      shutdown_states.each { | finish |
        v.shutdown = start
        assert_equal(start, v.shutdown, "start")
        v.shutdown = finish
        assert_equal(finish, v.shutdown, "finish")
      }
    }
    v.destroy
  end

  def test_vlan_add_remove_interface_valid
    v = Vlan.new(1000)
    interfaces = Interface.interfaces
    interfaces_added_to_vlan = []
    count = 3
    interfaces.each { | name, interface |
      if interface.name.match(/ethernet/) && count > 0
        interfaces_added_to_vlan << name
        interface.switchport_mode = :access
        v.add_interface(interface)
        count -= 1
      end
    }

    interfaces = v.interfaces
    interfaces.each { | name, interface |
      assert_includes(interfaces_added_to_vlan, name)
      assert_equal(v.vlan_id, interface.access_vlan, "Interface.access_vlan")
      v.remove_interface(interface)
    }

    interfaces = v.interfaces
    assert(interfaces.empty?)
    v.destroy
  end

  def test_vlan_add_interface_invalid
    v = Vlan.new(1000)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    assert_raises(RuntimeError) {
      v.add_interface(interface)
    }
    v.destroy
    interface_ethernet_default(interfaces_id[0])
  end

  def test_vlan_remove_interface_invalid
    v = Vlan.new(1000)
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :access
    v.add_interface(interface)
    interface.switchport_mode = :disabled
    assert_raises(RuntimeError) {
      v.remove_interface(interface)
    }

    v.destroy
    interface_ethernet_default(interfaces_id[0])
  end
end
