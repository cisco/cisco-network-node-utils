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
require_relative '../lib/cisco_node_utils/vxlan_vtep'
require_relative '../lib/cisco_node_utils/vxlan_vtep_vni'

include Cisco

# TestVxlanVtepVni - Minitest for VxlanVtepVni node utility
class TestVxlanVtepVni < CiscoTestCase
  @skip_unless_supported = 'vxlan_vtep_vni'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    vdc_limit_f3_no_intf_needed(:set) if VxlanVtep.mt_full_support
    Interface.interfaces(:nve).each { |_nve, obj| obj.destroy }
    feature_cleanup if @@pre_clean_needed
    Feature.nv_overlay_enable
    config_no_warn('feature vn-segment-vlan-based') if VxlanVtep.mt_lite_support
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

  def test_create_with_existing
    VxlanVtep.new('nve1').host_reachability = 'evpn'
    associate_vrf = true
    member = '5000'

    VxlanVtepVni.new('nve1', member)
    assert_includes(VxlanVtepVni.vnis['nve1'], member)

    VxlanVtepVni.new('nve1', member, associate_vrf)
    assert_includes(VxlanVtepVni.vnis['nve1'], member)
    assert(VxlanVtepVni.vnis['nve1'], associate_vrf)

    VxlanVtepVni.new('nve1', member)
    assert_includes(VxlanVtepVni.vnis['nve1'], member)
  end

  def test_vnis
    VxlanVtep.new('nve1')
    skip('Platform does not support vnis') if VxlanVtepVni.vnis['nve1'].nil?

    # Test empty case
    assert_empty(VxlanVtepVni.vnis['nve1'])

    # Host reachablity must be set to evpn for associate_vrf
    # testing.
    VxlanVtep.new('nve1').host_reachability = 'evpn'
    associate_vrf = true

    # Create one
    member1 = '5000'
    vni1 = VxlanVtepVni.new('nve1', member1, associate_vrf)
    assert_includes(VxlanVtepVni.vnis['nve1'], member1)
    assert(VxlanVtepVni.vnis['nve1'], associate_vrf)
    assert_equal(VxlanVtepVni.vnis['nve1'][member1], vni1)

    # Create several
    member2 = '5001-6001'
    member3 = '8888'
    refute_includes(VxlanVtepVni.vnis['nve1'], member2)
    refute_includes(VxlanVtepVni.vnis['nve1'], member3)

    vni2 = VxlanVtepVni.new('nve1', member2)
    vni3 = VxlanVtepVni.new('nve1', member3)
    assert_includes(VxlanVtepVni.vnis['nve1'], member2)
    assert_equal(VxlanVtepVni.vnis['nve1'][member2], vni2)
    assert_includes(VxlanVtepVni.vnis['nve1'], member3)
    assert_equal(VxlanVtepVni.vnis['nve1'][member3], vni3)

    # Destroy one
    vni2.destroy
    refute_includes(VxlanVtepVni.vnis['nve1'], member2)
    refute_equal(VxlanVtepVni.vnis['nve1'][member2], vni2)

    # Destroy all
    vni1.destroy
    vni3.destroy
    assert_empty(VxlanVtepVni.vnis['nve1'])
  end

  def test_ingress_replication
    skip_legacy_defect?('7.0.3.I3.1',
                        'CSCuy27700: Validation failed for vni mcast group configured')

    vni = VxlanVtepVni.new('nve1', '5000')
    if validate_property_excluded?('vxlan_vtep_vni', 'ingress_replication')
      assert_raises(Cisco::UnsupportedError) { vni.ingress_replication = 'bgp' }
      return
    end

    skip_incompat_version?('vxlan_vtep_vni', 'ingress_replication')
    # Test non-default values
    vni.ingress_replication = 'static'
    assert_equal('static', vni.ingress_replication)

    vni.ingress_replication = 'bgp'
    assert_equal('bgp', vni.ingress_replication)

    # Test default case
    ir = vni.default_ingress_replication
    vni.ingress_replication = ir
    assert_equal(ir, vni.ingress_replication)

    # Test the case where an existing multicast_group is removed before
    # configuring ingress_replication
    vni.multicast_group = '224.1.1.1'
    assert_equal('224.1.1.1', vni.multicast_group)

    vni.ingress_replication = 'static'
    assert_equal('static', vni.ingress_replication)
  end

  def test_multicast_group
    skip_legacy_defect?('7.0.3.I3.1',
                        'CSCuy27700: Validation failed for vni mcast group configured')

    vni1 = VxlanVtepVni.new('nve1', '6000')
    vni2 = VxlanVtepVni.new('nve1', '8001-8200')

    # No multicast groups configured
    assert_empty(vni1.multicast_group)

    # Test single multicast group
    vni1.multicast_group = '224.1.1.1'
    assert_equal('224.1.1.1', vni1.multicast_group)

    # Test the case where an existing ingress_replication is removed before
    # configuring multicast_group
    skip_incompat_version?('vxlan_vtep_vni', 'ingress_replication')
    unless validate_property_excluded?('vxlan_vtep_vni', 'ingress_replication')
      vni1.ingress_replication = 'static'
      assert_equal('static', vni1.ingress_replication)

      vni1.multicast_group = '224.1.1.1'
      assert_equal('224.1.1.1', vni1.multicast_group)
    end

    # Test multicast group range
    vni2.multicast_group = '224.1.1.1 224.1.1.200'
    assert_equal('224.1.1.1 224.1.1.200', vni2.multicast_group)

    # Test default
    vni1.multicast_group = vni1.default_multicast_group
    assert_empty(vni1.multicast_group)
    vni2.multicast_group = vni2.default_multicast_group
    assert_empty(vni2.multicast_group)
  end

  def test_peer_list
    vni = VxlanVtepVni.new('nve1', '6000')
    if validate_property_excluded?('vxlan_vtep_vni', 'peer_list')
      assert_raises(Cisco::UnsupportedError) { vni.peer_list = ['1.1.1.1'] }
      return
    end

    skip_incompat_version?('vxlan_vtep_vni', 'peer_list')
    peer_list = ['1.1.1.1', '2.2.2.2', '3.3.3.3', '4.4.4.4']

    # Test: all peers when current is empty
    should = peer_list.clone
    vni.peer_list = should
    result = vni.peer_list
    assert_equal(should.sort, result.sort,
                 'Test 1. From empty, to all peers')

    # Test: remove half of the peers
    should.shift(2)
    vni.peer_list = should
    result = vni.peer_list
    assert_equal(should.sort, result.sort,
                 'Test 2. Remove half of the peers')

    # Test: restore removed peers
    should = peer_list.clone
    vni.peer_list = should
    result = vni.peer_list
    assert_equal(should.sort, result.sort,
                 'Test 3. Restore removed peers')

    # Test: default
    should = vni.default_peer_list
    vni.peer_list = should
    result = vni.peer_list
    assert_equal(should.sort, result.sort,
                 'Test 4. Default')
  end

  def test_suppress_arp
    vni = VxlanVtepVni.new('nve1', '6000')
    VxlanVtep.new('nve1').host_reachability = 'evpn'

    # Test: Check suppress_arp is not configured.
    refute(vni.suppress_arp, 'suppress_arp should be disabled')

    begin
      # Test: Enable suppress_arp
      vni.suppress_arp = true
      assert(vni.suppress_arp, 'suppress_arp should be enabled')
    rescue CliError => e
      msg = 'TCAM reconfiguration required followed by reload' \
        " Skipping test case.\n#{e}"
      skip(msg) if /ERROR: Please configure TCAM/.match(e.to_s)
    end

    # Test: Default
    vni.suppress_arp = vni.default_suppress_arp
    refute(vni.suppress_arp, 'suppress_arp should be disabled')
  end

  def test_suppress_uuc
    vni = VxlanVtepVni.new('nve1', '6000')
    VxlanVtep.new('nve1').host_reachability = 'evpn'
    if validate_property_excluded?('vxlan_vtep_vni', 'suppress_uuc')
      assert_nil(vni.suppress_uuc)
      assert_nil(vni.default_suppress_uuc)
      assert_raises(Cisco::UnsupportedError) { vni.suppress_uuc = true }
      return
    end

    skip_incompat_version?('vxlan_vtep_vni', 'suppress_uuc')
    # Test: Check suppress_uuc is not configured.
    refute(vni.suppress_uuc, 'suppress_uuc should be disabled')

    # Test: Enable suppress_uuc
    vni.suppress_uuc = true
    assert(vni.suppress_uuc, 'suppress_uuc should be enabled')

    # Test: Default
    vni.suppress_uuc = vni.default_suppress_uuc
    refute(vni.suppress_uuc, 'suppress_uuc should be disabled')
  end
end
