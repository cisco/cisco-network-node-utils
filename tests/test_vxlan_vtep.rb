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
require_relative '../lib/cisco_node_utils/feature'
require_relative '../lib/cisco_node_utils/vxlan_vtep'
require_relative '../lib/cisco_node_utils/vdc'

include Cisco

# TestVxlanGlobal - Minitest for VxlanGlobal node utility
class TestVxlanVtep < CiscoTestCase
  def setup
    super
    skip('Platform does not support MT-full or MT-lite') unless
      VxlanVtep.mt_full_support || VxlanVtep.mt_lite_support
  end

  def teardown
    return unless Vdc.vdc_support
    # Reset the vdc module type back to default
    v = Vdc.new('default')
    v.limit_resource_module_type = '' if v.limit_resource_module_type == 'f3'
  end

  def compatible_interface?
    # MT-full tests require a specific linecard; either because they need a
    # compatible interface or simply to enable the features. Either way
    # we will provide an appropriate interface name if the linecard is present.
    # Example 'show mod' output to match against:
    #   '9  12  10/40 Gbps Ethernet Module  N7K-F312FQ-25 ok'
    sh_mod = @device.cmd("sh mod | i '^[0-9]+.*N7K-F3'")[/^(\d+)\s.*N7K-F3/]
    slot = sh_mod.nil? ? nil : Regexp.last_match[1]
    skip('Unable to find a compatible interface in chassis') if slot.nil?

    "ethernet#{slot}/1"
  end

  def mt_full_env_setup
    skip('Platform does not support MT-full') unless VxlanVtep.mt_full_support
    compatible_interface?
    v = Vdc.new('default')
    v.limit_resource_module_type = 'f3' unless
      v.limit_resource_module_type == 'f3'
    config('no feature nv overlay')
  end

  def mt_lite_env_setup
    skip('Platform does not support MT-lite') unless VxlanVtep.mt_lite_support
    config('no feature nv overlay')
    config('no feature vn-segment-vlan-based')
  end

  def test_create_destroy_one
    # VxlanVtep.new() will enable 'feature nv overlay'
    mt_full_env_setup if VxlanVtep.mt_full_support
    mt_lite_env_setup if VxlanVtep.mt_lite_support

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

  def test_mt_full_create_destroy_multiple
    if VxlanVtep.mt_full_support
      mt_full_env_setup
    else
      skip('Platform does not support MT-full')
    end

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

  def test_create_negative
    # MT-lite supports a single nve int, MT-full supports 4.
    mt_full_env_setup if VxlanVtep.mt_full_support
    mt_lite_env_setup if VxlanVtep.mt_lite_support
    if VxlanVtep.mt_lite_support
      VxlanVtep.new('nve1')
      negative_id = 'nve2'

    elsif VxlanVtep.mt_full_support
      mt_full_env_setup
      (1..4).each { |n| VxlanVtep.new("nve#{n}") }
      negative_id = 'nve5'
    end

    assert_raises(CliError) do
      VxlanVtep.new(negative_id)
    end
  end

  def test_description
    mt_full_env_setup if VxlanVtep.mt_full_support
    mt_lite_env_setup if VxlanVtep.mt_lite_support

    vtep = VxlanVtep.new('nve1')

    # Set description to non-default value and verify
    desc = 'vxlan interface'
    vtep.description = desc
    assert_equal(desc, vtep.description)

    # Set description to default value and verify
    desc = vtep.default_description
    vtep.description = desc
    assert_equal(desc, vtep.description)
  end

  def test_host_reachability
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vxlan_vtep', 'host_reachability').default_value.nil?
    mt_full_env_setup if VxlanVtep.mt_full_support
    mt_lite_env_setup if VxlanVtep.mt_lite_support

    vtep = VxlanVtep.new('nve1')

    vtep.host_reachability = 'flood'
    assert_equal('flood', vtep.host_reachability)
    vtep.host_reachability = 'evpn'
    assert_equal('evpn', vtep.host_reachability)

    # Set value back to flood, currently evpn.
    vtep.host_reachability = 'flood'
    assert_equal('flood', vtep.host_reachability)
  end

  def test_shutdown
    mt_full_env_setup if VxlanVtep.mt_full_support
    mt_lite_env_setup if VxlanVtep.mt_lite_support

    vtep = VxlanVtep.new('nve1')

    vtep.shutdown = true
    assert(vtep.shutdown, 'source_interface is not shutdown')

    vtep.shutdown = false
    refute(vtep.shutdown, 'source_interface is shutdown')

    vtep.shutdown = vtep.default_shutdown
    assert(vtep.shutdown, 'source_interface is not shutdown')
  end

  def test_source_interface
    mt_full_env_setup if VxlanVtep.mt_full_support
    mt_lite_env_setup if VxlanVtep.mt_lite_support

    vtep = VxlanVtep.new('nve1')

    # Set source_interface to non-default value
    val = 'loopback55'
    vtep.source_interface = val
    assert_equal(val, vtep.source_interface)

    # Change source_interface when nve interface is in a 'no shutdown' state
    vtep.shutdown = false
    val = 'loopback77'
    vtep.source_interface = val
    assert_equal(val, vtep.source_interface)
    # source_interface should 'no shutdown' after the change.
    refute(vtep.shutdown, 'source_interface is shutdown')

    # Set source_interface to default value
    val = vtep.default_source_interface
    vtep.source_interface = val
    assert_equal(val, vtep.source_interface)
  end
end
