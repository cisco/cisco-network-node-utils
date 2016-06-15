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

include Cisco
# TestInterface - Minitest for general functionality
# of the ItdDeviceGroup class.
class TestItdDevGrpNode < CiscoTestCase
  @skip_unless_supported = 'itd_device_group'
  # Tests

  def setup
    super
    config 'no feature itd'
  end

  def teardown
    config 'no feature itd'
    super
  end

  def test_create_destroy
    skip_nexus_i2_image?
    itddg1 = ItdDeviceGroup.new('abc')
    n1 = ItdDeviceGroupNode.new(itddg1.name, '1.1.1.1', 'ip')
    n2 = ItdDeviceGroupNode.new(itddg1.name, '2.2.2.2', 'ip')
    n3 = ItdDeviceGroupNode.new(itddg1.name, '3.3.3.3', 'ip')
    assert_includes(ItdDeviceGroupNode.itd_nodes['abc'], '1.1.1.1')
    assert_includes(ItdDeviceGroupNode.itd_nodes['abc'], '2.2.2.2')
    assert_includes(ItdDeviceGroupNode.itd_nodes['abc'], '3.3.3.3')
    itddg2 = ItdDeviceGroup.new('xyz')
    n4 = ItdDeviceGroupNode.new(itddg2.name, '2000::1', 'IPv6')
    assert_includes(ItdDeviceGroupNode.itd_nodes['xyz'], '2000::1')
    itddg3 = ItdDeviceGroup.new('efg')
    n5 = ItdDeviceGroupNode.new(itddg3.name, '1.1.1.1', 'ip')
    assert_includes(ItdDeviceGroupNode.itd_nodes['efg'], '1.1.1.1')

    n1.destroy
    refute_includes(ItdDeviceGroupNode.itd_nodes['abc'], '1.1.1.1')
    n2.destroy
    n3.destroy
    assert_empty(ItdDeviceGroupNode.itd_nodes['abc'])
    n4.destroy
    assert_empty(ItdDeviceGroupNode.itd_nodes['xyz'])
    n5.destroy
    assert_empty(ItdDeviceGroupNode.itd_nodes['efg'])
  end

  def probe_helper(props)
    test_hash = {
      probe_frequency:  9,
      probe_retry_down: 5,
      probe_retry_up:   5,
      probe_timeout:    6,
    }.merge!(props)

    ItdDeviceGroup.new('new_group')
    idg = ItdDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
    idg.probe_set(test_hash)
    idg
  end

  def test_probe_icmp
    skip_nexus_i2_image?
    idg = probe_helper(probe_type: 'icmp')
    assert_equal('icmp', idg.probe_type)
    assert_equal(9, idg.probe_frequency)
    assert_equal(6, idg.probe_timeout)
    assert_equal(5, idg.probe_retry_up)
    assert_equal(5, idg.probe_retry_down)
    idg = probe_helper(probe_type:       'icmp',
                       probe_frequency:  idg.default_probe_frequency,
                       probe_retry_up:   idg.default_probe_retry_up,
                       probe_retry_down: idg.default_probe_retry_down,
                       probe_timeout:    idg.default_probe_timeout)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    idg = probe_helper(probe_type: idg.default_probe_type)
    assert_equal(idg.default_probe_type, idg.probe_type)
    idg.destroy
  end

  def test_probe_dns
    skip_nexus_i2_image?
    host = 'resolver1.opendns.com'
    idg = probe_helper(probe_type: 'dns', probe_dns_host: host)
    assert_equal('dns', idg.probe_type)
    assert_equal(host, idg.probe_dns_host)
    assert_equal(9, idg.probe_frequency)
    assert_equal(6, idg.probe_timeout)
    assert_equal(5, idg.probe_retry_up)
    assert_equal(5, idg.probe_retry_down)
    host = '208.67.220.222'
    idg = probe_helper(probe_type: 'dns', probe_dns_host: host,
            probe_frequency: idg.default_probe_frequency,
            probe_retry_up: idg.default_probe_retry_up,
            probe_retry_down: idg.default_probe_retry_down,
            probe_timeout: idg.default_probe_timeout)
    assert_equal(host, idg.probe_dns_host)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    host = '2620:0:ccd::2'
    idg = probe_helper(probe_type: 'dns', probe_dns_host: host,
            probe_frequency: idg.default_probe_frequency,
            probe_retry_up: idg.default_probe_retry_up,
            probe_retry_down: idg.default_probe_retry_down,
            probe_timeout: idg.default_probe_timeout)
    assert_equal(host, idg.probe_dns_host)
    idg.destroy
  end

  def test_probe_tcp_udp
    skip_nexus_i2_image?
    port = 11_111
    type = 'tcp'
    idg = probe_helper(probe_type: type, probe_port: port,
                      probe_control: true)
    assert_equal(type, idg.probe_type)
    assert_equal(port, idg.probe_port)
    assert_equal(true, idg.probe_control)
    assert_equal(9, idg.probe_frequency)
    assert_equal(6, idg.probe_timeout)
    assert_equal(5, idg.probe_retry_up)
    assert_equal(5, idg.probe_retry_down)
    type = 'udp'
    idg = probe_helper(probe_type: type, probe_port: port,
            probe_control: idg.default_probe_control,
            probe_frequency: idg.default_probe_frequency,
            probe_retry_up: idg.default_probe_retry_up,
            probe_retry_down: idg.default_probe_retry_down,
            probe_timeout: idg.default_probe_timeout)
    assert_equal(type, idg.probe_type)
    assert_equal(port, idg.probe_port)
    assert_equal(idg.default_probe_control, idg.probe_control)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    idg.destroy
  end

  def test_hot_standby_weight
    skip_nexus_i2_image?
    itddg = ItdDeviceGroup.new('new_group')
    idg = ItdDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
    hot_standby = true
    weight = idg.default_weight
    idg.hs_weight(hot_standby, weight)
    assert_equal(true, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = idg.default_weight
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 150
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(150, idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 200
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(200, idg.weight)
    hot_standby = true
    weight = idg.default_weight
    idg.hs_weight(hot_standby, weight)
    assert_equal(true, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 200
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(200, idg.weight)
    idg.destroy
    itddg.destroy
  end
end
