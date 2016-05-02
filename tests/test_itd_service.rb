# Copyright (c) 2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/itd_device_group_node'
require_relative '../lib/cisco_node_utils/itd_service'

include Cisco
# TestInterface - Minitest for general functionality
# of the ItdService class.
class TestItdService < CiscoTestCase
  @skip_unless_supported = 'itd_service'
  # Tests

  def setup
    super
    config 'no feature itd'
  end

  def teardown
    config 'no feature itd'
    super
  end

  def test_itd_service_create_destroy
    skip_nexus_i2_image?
    i1 = ItdService.new('abc')
    i2 = ItdService.new('BCD')
    i3 = ItdService.new('xyzABC')
    assert_equal(3, ItdService.itds.keys.count)

    i2.destroy
    assert_equal(2, ItdService.itds.keys.count)

    i1.destroy
    i3.destroy
    assert_equal(0, ItdService.itds.keys.count)
  end

  def test_access_list
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    config 'ip access-list include'
    config 'ip access-list exclude'
    itd.access_list = 'include'
    itd.exclude_access_list = 'exclude'
    assert_equal('include', itd.access_list)
    assert_equal('exclude', itd.exclude_access_list)
    itd.access_list = itd.default_access_list
    itd.exclude_access_list = itd.default_exclude_access_list
    assert_equal(itd.default_access_list,
                 itd.access_list)
    assert_equal(itd.default_exclude_access_list,
                 itd.exclude_access_list)
    config 'no ip access-list include'
    config 'no ip access-list exclude'
  end

  def test_device_group
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    ItdDeviceGroup.new('myGroup')
    itd.device_group = 'myGroup'
    assert_equal('myGroup', itd.device_group)
    itd.device_group = itd.default_device_group
    assert_equal(itd.default_device_group,
                 itd.device_group)
  end

  def test_fail_action
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    itd.fail_action = true
    assert_equal(true, itd.fail_action)
    itd.fail_action = itd.default_fail_action
    assert_equal(itd.default_fail_action,
                 itd.fail_action)
  end

  def test_ingress_interface
    skip_nexus_i2_image?
    config 'feature interface-vlan'
    config 'vlan 2'
    config 'interface vlan 2'
    config 'interface port-channel 100 ; no switchport'
    itd = ItdService.new('new_group')
    intf = interfaces[0].dup
    new_intf = Interface.new(interfaces[0])
    new_intf.switchport_mode = :disabled
    ii = [['vlan 2', '1.1.1.1'],
          [intf.insert(8, ' '), '2.2.2.2'],
          ['port-channel 100', '3.3.3.3']]
    itd.ingress_interface = ii
    assert_equal(itd.ingress_interface, ii)
    itd.ingress_interface = itd.default_ingress_interface
    assert_equal(itd.ingress_interface, itd.default_ingress_interface)
    config 'no interface port-channel 100'
    config 'no interface vlan 2'
    config 'no vlan 2'
    config 'no feature interface-vlan'
  end

  def lb_helper(props)
    itd = ItdService.new('new_group')
    test_hash = {
      load_bal_enable:               true,
      load_bal_method_bundle_select: itd.default_load_bal_method_bundle_select,
      load_bal_method_bundle_hash:   itd.default_load_bal_method_bundle_hash,
      load_bal_method_proto:         itd.default_load_bal_method_proto,
      load_bal_buckets:              itd.default_load_bal_buckets,
      load_bal_method_end_port:      itd.default_load_bal_method_end_port,
      load_bal_method_start_port:    itd.default_load_bal_method_start_port,
    }.merge!(props)
    itd.load_balance_set(test_hash)
    itd
  end

  def test_load_balance
    skip_nexus_i2_image?
    itd = lb_helper(load_bal_method_bundle_select: 'src',
                    load_bal_method_bundle_hash:   'ip',
                    load_bal_buckets:              16,
                    load_bal_mask_pos:             4)
    assert_equal(true, itd.load_bal_enable)
    assert_equal(16, itd.load_bal_buckets)
    assert_equal(4, itd.load_bal_mask_pos)
    assert_equal('ip', itd.load_bal_method_bundle_hash)
    assert_equal('src', itd.load_bal_method_bundle_select)
    itd = lb_helper(load_bal_enable:               true,
                    load_bal_method_bundle_select: 'dst',
                    load_bal_method_bundle_hash:   'ip-l4port',
                    load_bal_buckets:              128,
                    load_bal_mask_pos:             10,
                    load_bal_method_end_port:      700,
                    load_bal_method_proto:         'tcp',
                    load_bal_method_start_port:    200)
    assert_equal(128, itd.load_bal_buckets)
    assert_equal(10, itd.load_bal_mask_pos)
    assert_equal('ip-l4port', itd.load_bal_method_bundle_hash)
    assert_equal('dst', itd.load_bal_method_bundle_select)
    assert_equal(700, itd.load_bal_method_end_port)
    assert_equal(200, itd.load_bal_method_start_port)
    assert_equal('tcp', itd.load_bal_method_proto)
    itd = lb_helper(load_bal_mask_pos: 20)
    assert_equal(itd.default_load_bal_buckets,
                 itd.load_bal_buckets)
    assert_equal(20, itd.load_bal_mask_pos)
    assert_equal(itd.default_load_bal_method_bundle_hash,
                 itd.load_bal_method_bundle_hash)
    assert_equal(itd.default_load_bal_method_bundle_select,
                 itd.load_bal_method_bundle_select)
    assert_equal(itd.default_load_bal_method_end_port,
                 itd.load_bal_method_end_port)
    assert_equal(itd.default_load_bal_method_start_port,
                 itd.load_bal_method_start_port)
    assert_equal(itd.default_load_bal_method_proto,
                 itd.load_bal_method_proto)
    itd = lb_helper(load_bal_enable:  true,
                    load_bal_buckets: 256)
    assert_equal(256, itd.load_bal_buckets)
    assert_equal(itd.default_load_bal_mask_pos,
                 itd.load_bal_mask_pos)
    assert_equal(itd.default_load_bal_method_bundle_hash,
                 itd.load_bal_method_bundle_hash)
    assert_equal(itd.default_load_bal_method_bundle_select,
                 itd.load_bal_method_bundle_select)
    assert_equal(itd.default_load_bal_method_end_port,
                 itd.load_bal_method_end_port)
    assert_equal(itd.default_load_bal_method_start_port,
                 itd.load_bal_method_start_port)
    assert_equal(itd.default_load_bal_method_proto,
                 itd.load_bal_method_proto)
    itd = lb_helper(load_bal_enable: false)
    assert_equal(itd.load_bal_enable,
                 itd.default_load_bal_enable)
    assert_equal(itd.load_bal_buckets, itd.default_load_bal_buckets)
    assert_equal(itd.load_bal_mask_pos, itd.default_load_bal_mask_pos)
    assert_equal(itd.load_bal_method_bundle_hash,
                 itd.default_load_bal_method_bundle_hash)
    assert_equal(itd.load_bal_method_bundle_select,
                 itd.default_load_bal_method_bundle_select)
    assert_equal(itd.load_bal_method_end_port,
                 itd.default_load_bal_method_end_port)
    assert_equal(itd.load_bal_method_start_port,
                 itd.default_load_bal_method_start_port)
    assert_equal(itd.load_bal_method_proto,
                 itd.default_load_bal_method_proto)
  end

  def test_nat_destination
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    if validate_property_excluded?('itd_service', 'nat_destination')
      assert_nil(itd.nat_destination)
      assert_raises(Cisco::UnsupportedError) do
        itd.nat_destination = false
      end
      return
    end
    itddg = ItdDeviceGroup.new('abc')
    ItdDeviceGroupNode.new(itddg.name, '1.1.1.1', 'ip')
    itd.device_group = 'abc'
    itd.virtual_ip = ['ip 2.2.2.2 255.255.255.0']
    intf = interfaces[0].dup
    new_intf = Interface.new(interfaces[0])
    new_intf.switchport_mode = :disabled
    ii = [[intf.insert(8, ' '), '2.2.2.2']]
    itd.ingress_interface = ii
    itd.nat_destination = true
    assert_equal(true, itd.nat_destination)
    itd.nat_destination = itd.default_nat_destination
    assert_equal(itd.default_nat_destination, itd.nat_destination)
  end

  def test_shutdown
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    itddg = ItdDeviceGroup.new('abc')
    ItdDeviceGroupNode.new(itddg.name, '1.1.1.1', 'ip')
    itd.device_group = 'abc'
    itd.virtual_ip = ['ip 2.2.2.2 255.255.255.0']
    intf = Interface.new(interfaces[0])
    new_intf = Interface.new(interfaces[0])
    new_intf.switchport_mode = :disabled
    intf.switchport_mode = :disabled
    intf_dup = interfaces[0].dup
    ii = [[intf_dup.insert(8, ' '), '2.2.2.2']]
    itd.ingress_interface = ii
    itd.shutdown = false
    assert_equal(false, itd.shutdown)
    itd.shutdown = itd.default_shutdown
    assert_equal(itd.default_shutdown,
                 itd.shutdown)
  end

  def test_peer_vdc
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    parray = %w(vdc1 ser1)
    if validate_property_excluded?('itd_service', 'peer_vdc')
      assert_nil(itd.peer_vdc)
      assert_raises(Cisco::UnsupportedError) do
        itd.peer_vdc = parray
      end
      return
    end
    itd.peer_vdc = parray
    assert_equal(parray, itd.peer_vdc)
    itd.peer_vdc = itd.default_peer_vdc
    assert_equal(itd.default_peer_vdc,
                 itd.peer_vdc)
  end

  def test_peer_local
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    service = 'ser1'
    if validate_property_excluded?('itd_service', 'peer_local')
      assert_nil(itd.peer_local)
      assert_raises(Cisco::UnsupportedError) do
        itd.peer_local = service
      end
      return
    end
    itd.peer_local = service
    assert_equal(service, itd.peer_local)
    itd.peer_local = itd.default_peer_local
    assert_equal(itd.default_peer_local,
                 itd.peer_local)
  end

  def test_virtual_ip
    skip_nexus_i2_image?
    itd = ItdService.new('new_group')
    ItdDeviceGroup.new('myGroup1')
    ItdDeviceGroup.new('myGroup2')
    values = ['ip 1.1.1.1 255.255.255.0 tcp 2000 advertise enable',
              'ip 2.2.2.2 255.0.0.0 udp 1000 device-group myGroup1',
              'ip 3.3.3.3 255.0.255.0 device-group myGroup2']
    itd.virtual_ip = values
    assert_equal(itd.virtual_ip,
                 values)
    itd.virtual_ip = itd.default_virtual_ip
    assert_equal(itd.virtual_ip,
                 itd.default_virtual_ip)
  end
end
