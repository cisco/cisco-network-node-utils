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
class TestItdDeviceGroupNode < CiscoTestCase
  # Tests

  def setup
    super
    config 'no feature itd' if n79k_platform?
  end

  def teardown
    config 'no feature itd' if n79k_platform?
    super
  end

  def n79k_platform?
    /N(7|9)/ =~ node.product_id
  end

  def test_itd_device_group_node_create_destroy
    skip('Platform does not support this feature') unless n79k_platform?
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

  def test_probe_icmp
    skip('Platform does not support this feature') unless n79k_platform?
    itddg = ItdDeviceGroup.new('new_group')
    idg = ItdDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
    type = 'icmp'
    freq = 9
    rd = 5
    ru = 5
    to = 6
    idg.send(:probe=, type, nil, nil, freq, ru, rd, nil, to)
    assert_equal(type, idg.probe_type)
    assert_equal(freq, idg.probe_frequency)
    assert_equal(to, idg.probe_timeout)
    assert_equal(ru, idg.probe_retry_up)
    assert_equal(rd, idg.probe_retry_down)
    idg.send(:probe=, type, nil, nil,
             idg.default_probe_frequency,
             idg.default_probe_retry_up,
             idg.default_probe_retry_down,
             nil,
             idg.default_probe_timeout)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    idg.send(:probe=, idg.default_probe_type,
             nil, nil, nil, nil, nil, nil, nil)
    assert_equal(idg.default_probe_type, idg.probe_type)
    idg.destroy
    itddg.destroy
  end

  def test_probe_dns
    skip('Platform does not support this feature') unless n79k_platform?
    itddg = ItdDeviceGroup.new('new_group')
    idg = ItdDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
    host = 'resolver1.opendns.com'
    type = 'dns'
    freq = 9
    rd = 5
    ru = 5
    to = 6
    idg.send(:probe=, type, host, nil, freq, ru, rd, nil, to)
    assert_equal(type, idg.probe_type)
    assert_equal(host, idg.probe_dns_host)
    assert_equal(freq, idg.probe_frequency)
    assert_equal(to, idg.probe_timeout)
    assert_equal(ru, idg.probe_retry_up)
    assert_equal(rd, idg.probe_retry_down)
    host = '208.67.220.222'
    idg.send(:probe=, type, host, nil,
             idg.default_probe_frequency,
             idg.default_probe_retry_up,
             idg.default_probe_retry_down,
             nil,
             idg.default_probe_timeout)
    assert_equal(host, idg.probe_dns_host)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    host = '2620:0:ccd::2'
    idg.send(:probe=, type, host, nil,
             idg.default_probe_frequency,
             idg.default_probe_retry_up,
             idg.default_probe_retry_down,
             nil,
             idg.default_probe_timeout)
    assert_equal(host, idg.probe_dns_host)
    idg.destroy
    itddg.destroy
  end

  def test_probe_tcp_udp
    skip('Platform does not support this feature') unless n79k_platform?
    itddg = ItdDeviceGroup.new('new_group')
    idg = ItdDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
    port = 11_111
    type = 'tcp'
    freq = 9
    rd = 5
    ru = 5
    to = 6
    control = true
    idg.send(:probe=, type, nil, control, freq, ru, rd, port, to)
    assert_equal(type, idg.probe_type)
    assert_equal(port, idg.probe_port)
    assert_equal(control, idg.probe_control)
    assert_equal(freq, idg.probe_frequency)
    assert_equal(to, idg.probe_timeout)
    assert_equal(ru, idg.probe_retry_up)
    assert_equal(rd, idg.probe_retry_down)
    type = 'udp'
    idg.send(:probe=, type, nil,
             idg.default_probe_control,
             idg.default_probe_frequency,
             idg.default_probe_retry_up,
             idg.default_probe_retry_down,
             port,
             idg.default_probe_timeout)
    assert_equal(type, idg.probe_type)
    assert_equal(idg.default_probe_control, idg.probe_control)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    idg.destroy
    itddg.destroy
  end

  def test_hot_standby_weight
    skip('Platform does not support this feature') unless n79k_platform?
    itddg = ItdDeviceGroup.new('new_group')
    idg = ItdDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
    hot_standby = true
    weight = idg.default_weight
    idg.send(:hs_weight=, hot_standby, weight)
    assert_equal(true, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = idg.default_weight
    idg.send(:hs_weight=, hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 150
    idg.send(:hs_weight=, hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(150, idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 200
    idg.send(:hs_weight=, hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(200, idg.weight)
    hot_standby = true
    weight = idg.default_weight
    idg.send(:hs_weight=, hot_standby, weight)
    assert_equal(true, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 200
    idg.send(:hs_weight=, hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(200, idg.weight)
    idg.destroy
    itddg.destroy
  end
end
