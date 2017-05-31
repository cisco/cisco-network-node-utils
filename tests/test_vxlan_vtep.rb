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

# TestVxlanVtep - Minitest for VxlanVtep node utility
class TestVxlanVtep < CiscoTestCase
  @skip_unless_supported = 'vxlan_vtep'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    skip('Platform does not support MT-full or MT-lite') unless
      VxlanVtep.mt_full_support || VxlanVtep.mt_lite_support
    Interface.interfaces(:nve).each { |_nve, obj| obj.destroy }
    vdc_limit_f3_no_intf_needed(:set)
    feature_cleanup if @@pre_clean_needed
    Feature.nv_overlay_enable
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    if first_or_last_teardown
      vdc_limit_f3_no_intf_needed(:clear)
      feature_cleanup
    end
    super
  end

  def feature_cleanup
    config_no_warn('no feature-set fabricpath')
    config_no_warn('no feature vni')
    config_no_warn('no feature vn-segment-vlan-based')
    config_no_warn('no nv overlay evpn ; no feature nv overlay')
    # Rapid nv feature toggle can cause failures on some platforms;
    # symptom e.g. 'show runn | i ^feature' will hang
    sleep 5
  end

  def test_create_destroy_one
    # VxlanVtep.new() will enable 'feature nv overlay'
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
    skip('Platform does not support MT-full') unless VxlanVtep.mt_full_support

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
    if VxlanVtep.mt_lite_support
      VxlanVtep.new('nve1')
      negative_id = 'nve2'

    elsif VxlanVtep.mt_full_support
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
    assert_equal(desc, vtep.description)

    # Set description to default value and verify
    desc = vtep.default_description
    vtep.description = desc
    assert_equal(desc, vtep.description)
  end

  def test_host_reachability
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vxlan_vtep', 'host_reachability').default_value.nil?

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

  def test_source_interface_hold_down_time
    vtep = VxlanVtep.new('nve1')
    if validate_property_excluded?('vxlan_vtep', 'source_intf_hold_down_time')
      assert_nil(vtep.source_interface_hold_down_time)
      assert_nil(vtep.default_source_interface_hold_down_time)
      assert_raises(Cisco::UnsupportedError) do
        vtep.source_interface_hold_down_time = 50
      end
      return
    end

    skip_incompat_version?('vxlan_vtep', 'source_intf_hold_down_time')
    # Set source_interface to non-default value
    val = 'loopback55'
    vtep.source_interface = val
    assert_equal(val, vtep.source_interface)

    # Set source_interface_hold_down_time
    time = 50
    vtep.source_interface_hold_down_time = time
    assert_equal(time, vtep.source_interface_hold_down_time)

    # Set source_interface_hold_down_time to default value
    val = vtep.default_source_interface_hold_down_time
    vtep.source_interface_hold_down_time = val
    assert_equal(val, vtep.source_interface_hold_down_time)
  end
end
