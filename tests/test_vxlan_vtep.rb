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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/vxlan_vtep'

include Cisco

# TestVxlanGlobal - Minitest for VxlanGlobal node utility
class TestVxlanVtep < CiscoTestCase
  def setup
    super
    no_vxlan_global
  end

  def teardown
    no_vxlan_global
    super
  end

  def no_vxlan_global
    config('no feature nv overlay')
  end

  def test_create_destroy_one
    id = 'nve1'
    vtep = VxlanVtep.new(id)
    @default_show_command = "show running | i 'interface #{id}'"

    assert_show_match(pattern: /^interface #{id}$/,
                      msg:     "failed to create interface #{id}")

    assert_includes(Cisco::VxlanVtep.vteps, id)
    assert_equal(Cisco::VxlanVtep.vteps[id], vtep)

    vtep.destroy
    refute_show_match(pattern: /^interface #{id}$/,
                      msg:     "failed to destroy interface #{id}")
  end

  def test_create_destroy_multiple
    skip('Only supported on n7k') if node.product_id =~ /N[3|5|9]K/

    id1 = 'nve1'
    id2 = 'nve2'
    id3 = 'nve3'
    id4 = 'nve4'
    vtep1 = VxlanVtep.new(id1)
    vtep2 = VxlanVtep.new(id2)
    vtep3 = VxlanVtep.new(id3)
    vtep4 = VxlanVtep.new(id4)

    [id1, id2, id3, id4].each do |id|
      assert_show_match(command: "show running | i 'interface #{id}'",
                        pattern: /^interface #{id}$/,
                        msg:     "failed to create interface #{id}")
      assert_includes(Cisco::VxlanVtep.vteps, id)
    end

    vtep1.destroy
    vtep2.destroy
    vtep3.destroy
    vtep4.destroy

    [id1, id2, id3, id4].each do |id|
      refute_show_match(command: "show running | i 'interface #{id}'",
                        pattern: /^interface #{id}$/,
                        msg:     "failed to create interface #{id}")
    end
  end

  def test_create_multiple_negative
    # N[3|9]K supports a single nve int, N7K supports 4.
    case node.product_id
    when /N[3|9]K/
      VxlanVtep.new('nve1')
      negative_id = 'nve2'
    when /N7K/
      (1..4).each { |n| VxlanVtep.new("nve#{n}") }
      negative_id = 'nve5'
    end

    assert_raises(CliError) do
      VxlanVtep.new(negative_id)
    end
  end

  def test_description
    vtep = VxlanVtep.new('nve1')

    # Set description to non-default value and verify
    desc = 'vxlan interface'
    vtep.description = desc
    assert_equal(vtep.description, desc, "description is not #{desc}")

    # Set description to default value and verify
    desc = vtep.default_description
    vtep.description = desc
    assert_equal(vtep.description, desc, "description is not #{desc}")
  end

  def test_mac_distribution
    vtep = VxlanVtep.new('nve1')

    val = :flood
    vtep.mac_distribution = val
    assert_equal(vtep.mac_distribution, val.to_s,
                 "mac_distribution is not #{val}")

    val = :evpn
    vtep.mac_distribution = val
    assert_equal(vtep.mac_distribution, val.to_s,
                 "mac_distribution is not #{val}")

    # Set value back to flood, currently evpn.
    val = :flood
    vtep.mac_distribution = val
    assert_equal(vtep.mac_distribution, val.to_s,
                 "mac_distribution is not #{val}")
  end

  def test_shutdown
    vtep = VxlanVtep.new('nve1')

    vtep.shutdown = true
    assert(vtep.shutdown, 'source_interface is not shutdown')

    vtep.shutdown = false
    refute(vtep.shutdown, 'source_interface is shutdown')

    vtep.shutdown = vtep.default_shutdown
    assert(vtep.shutdown, 'source_interface is not shutdown')
  end

  def test_source_interface
    vtep = VxlanVtep.new('nve1')

    # Set source_interface to non-default value
    val = 'loopback55'
    vtep.source_interface = val
    assert_equal(vtep.source_interface, val, "source_interface is not #{val}")

    # Set source_interface to default value
    val = vtep.default_source_interface
    vtep.source_interface = val
    assert_equal(vtep.source_interface, val, "source_interface is not #{val}")
  end
end
