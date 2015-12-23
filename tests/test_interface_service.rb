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
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/interface_service'

include Cisco

# TestInterfaceService - Minitest for the InterfaceService class.
#
# Example cli tested by this minitest:
#
#  encapsulation profile vni vni_500_5000
#    dot1q 500  vni 5000
#  interface Ethernet9/1
#    service instance 5 vni
#      encapsulation profile vni_500_5000 default
#      shutdown
#    service instance 6 vni
#      encapsulation profile vni_600_6000 default
#
class TestInterfaceService < CiscoTestCase
  def setup_encapsulation_profile_vni
    # This property has several dependencies:
    #  - VDC support
    #  - Specific linecard (F3 or newer)
    #  - Bridge Domain Configuration
    #  - Feature vni

    # Check for supported platform
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vdc', 'all_vdcs').config_get_token.nil?

    # This test requires specific linecards; as such we will hard-code the
    # module location and skip the test if not found.
    # Example 'show mod' output to match against:
    # '9    12     10/40 Gbps Ethernet Module          N7K-F312FQ-25      ok'
    slot = 9
    pat = Regexp.new("^#{slot}\s.*N7K-F3")
    skip("Test requires N7K-F3 linecard in slot #{slot}") unless
      @device.cmd('sh mod | i N7K-F').match(pat)

    require_relative '../lib/cisco_node_utils/vdc'
    Cisco::Vdc.new('default').limit_resource_module_type = 'f3'

    # Reset feature to clean up switch
    config('no feature vni', 'feature vni')

    # Create a global encap config
    config('encapsulation profile vni vni_500_5000', 'dot1q 500  vni 5000',
           'encapsulation profile vni vni_600_6000', 'dot1q 600  vni 6000',
           'encapsulation profile vni vni_700_7000', 'dot1q 700  vni 7000',
           'encapsulation profile vni vni_800_8000', 'dot1q 800  vni 8000')

    # Test interface name
    intf = 'ethernet9/1'
    config("default int #{intf}")
    intf
  end

  def test_create_destroy
    intf = setup_encapsulation_profile_vni

    # TEST Create / Destroy and svc_vni_ids hash builder
    i5 = InterfaceService.new(intf, 5)
    assert_equal(1, InterfaceService.svc_vni_ids[intf].count)
    i6 = InterfaceService.new(intf, 6)
    i7 = InterfaceService.new(intf, 7)
    assert_equal(3, InterfaceService.svc_vni_ids[intf].count)
    i6.destroy
    assert_equal(2, InterfaceService.svc_vni_ids[intf].count)
    i5.destroy
    i7.destroy
  end

  def test_shutdown
    intf = setup_encapsulation_profile_vni

    i5 = InterfaceService.new(intf, 5)
    # Test shutdown
    i5.shutdown = false
    refute(i5.shutdown)
    i5.shutdown = true
    assert(i5.shutdown)
    i5.shutdown = false
    refute(i5.shutdown)
    i5.shutdown = i5.default_shutdown
    assert(i5.shutdown)
  end

  def test_encapsulation_profile_vni
    intf = setup_encapsulation_profile_vni

    i5 = InterfaceService.new(intf, 5)

    # Test removal when profile not present
    i5.encapsulation_profile_vni = ''
    assert_empty(i5.encapsulation_profile_vni)

    # Add one
    i5.encapsulation_profile_vni = 'vni_500_5000'
    assert_equal('vni_500_5000', i5.encapsulation_profile_vni)

    # Change it
    i5.encapsulation_profile_vni = 'vni_700_7000'
    assert_equal('vni_700_7000', i5.encapsulation_profile_vni)

    # Test default when profile present
    i5.encapsulation_profile_vni = 'vni_700_7000'
    i5.encapsulation_profile_vni = i5.default_encapsulation_profile_vni
    assert_equal(i5.default_encapsulation_profile_vni,
                 i5.encapsulation_profile_vni)
  end

  # interface vlan_mapping is not technically part of the interface service
  # but it shares most of the same dependencies so it is tested here instead
  # of test_interface.rb
  def setup_vlan_mapping
    # This property has several dependencies:
    #  - VDC support
    #  - Specific linecard (F3)
    #  - Bridge Domain Configuration
    #  - Feature vni

    # Check for supported platform
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vdc', 'all_vdcs').config_get_token.nil?

    # This test requires a specific linecard; as such we will hard-code the
    # module location and skip the test if not found.
    # Example 'show mod' output to match against:
    # '9    12     10/40 Gbps Ethernet Module          N7K-F312FQ-25      ok'
    slot = 9
    pat = Regexp.new("^#{slot}\s.*N7K-F3")
    skip("Test requires N7K-F3 linecard in slot #{slot}") unless
      @device.cmd('sh mod | i N7K-F').match(pat)

    require_relative '../lib/cisco_node_utils/vdc'
    Cisco::Vdc.new('default').limit_resource_module_type = 'f3'

    # Configure a bridge-domain
    config('system bridge-domain 100-113', 'bridge-domain 100')

    # Reset feature to clean up switch
    config('no feature vni')

    # Test interface name
    'Ethernet9/1'
  end

  def test_vlan_mapping
    # This test covers two properties:
    #  vlan_mapping & vlan_mapping_enabled

    intf = setup_vlan_mapping
    i = Interface.new(intf)
    i.switchport_mode = :trunk
    i.vlan_mapping = []
    assert_equal([], i.vlan_mapping, 'Initial cleanup failed')

    # Initial 'should' state
    # rubocop:disable Style/WordArray
    master = [['20', '21'],
              ['40', '41'],
              ['60', '61'],
              ['80', '81']]
    # rubocop:enable Style/WordArray

    # Test: Add all mappings when no cmds are present
    should = master.clone
    i.vlan_mapping = should
    result = i.vlan_mapping
    assert_equal(should.sort, result.sort,
                 'Test 1a. From empty, to all mappings')
    i.vlan_mapping_enable = false
    refute(i.vlan_mapping_enable,
           'Test 1b. Initial test, set to disabled')

    # Test: remove half of the mappings
    should.shift(2)
    i.vlan_mapping = should
    result = i.vlan_mapping
    assert_equal(should.sort, result.sort,
                 'Test 2a. Remove half of the mappings')
    i.vlan_mapping_enable = true
    assert(i.vlan_mapping_enable,
           'Test 2b. Back to enabled')

    # Test: restore the removed mappings
    should = master.clone
    i.vlan_mapping = should
    result = i.vlan_mapping
    assert_equal(should.sort, result.sort,
                 'Test 3a. Restore the removed mappings')
    i.vlan_mapping_enable = false
    refute(i.vlan_mapping_enable,
           'Test 3b. Back to disabled')

    # Test: Change original-vlan on existing commands
    should = should.map do |original, translated|
      [original + '1', translated]
    end
    i.vlan_mapping = should
    result = i.vlan_mapping
    assert_equal(should.sort, result.sort,
                 'Test 4. Change original-vlan on existing commands')

    # Test: Change translated-vlan on existing commands
    should = should.map do |original, translated|
      [original, translated + '1']
    end
    i.vlan_mapping = should
    result = i.vlan_mapping
    assert_equal(should.sort, result.sort,
                 'Test 5. Change translated-vlan on existing commands')

    # Test: 'default'
    should = i.default_vlan_mapping
    i.vlan_mapping = should
    result = i.vlan_mapping
    assert_equal(should.sort, result.sort,
                 "Test 6a. 'default'")
    i.vlan_mapping_enable = i.default_vlan_mapping_enable
    assert(i.vlan_mapping_enable,
           "Test 6b. 'default'")
  end
end
