# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/itd_device_group'

include Cisco
# TestInterface - Minitest for general functionality
# of the ItdDeviceGroup class.
class TestItdDeviceGroup < CiscoTestCase
  # Tests

  def setup
    super
    config 'no feature itd'
  end

  def teardown
    config 'no feature itd'
    super
  end

  def test_itd_device_group_create_destroy
    i1 = ItdDeviceGroup.new('abc')
    i2 = ItdDeviceGroup.new('BCD')
    i3 = ItdDeviceGroup.new('xyzABC')
    assert_equal(3, ItdDeviceGroup.itds.keys.count)

    i2.destroy
    assert_equal(2, ItdDeviceGroup.itds.keys.count)

    i1.destroy
    i3.destroy
    assert_equal(0, ItdDeviceGroup.itds.keys.count)
  end

  def test_probe_icmp
    idg = ItdDeviceGroup.new('new_group')
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
  end

  def test_probe_dns
    idg = ItdDeviceGroup.new('new_group')
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
  end

  def test_probe_tcp_udp
    idg = ItdDeviceGroup.new('new_group')
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
  end
end
