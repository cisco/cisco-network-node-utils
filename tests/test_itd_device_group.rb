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

  DEFAULT_NAME = 'new_group'

  def setup
    super
    config 'no feature itd'
  end

  def teardown
    config 'no feature itd'
    super
  end

  def test_create
    @idg = ItdDeviceGroup.new(DEFAULT_NAME)
  end

  def test_probe_icmp
    @idg = ItdDeviceGroup.new(DEFAULT_NAME)
    type = 'icmp'
    freq = 9
    rd = 5
    ru = 5
    to = 6
    @idg.send(:probe=, type, nil, nil, freq, ru, rd, nil, to)
    assert_equal(type, @idg.probe_type)
    assert_equal(freq, @idg.probe_frequency)
    assert_equal(to, @idg.probe_timeout)
    assert_equal(ru, @idg.probe_retry_up)
    assert_equal(rd, @idg.probe_retry_down)
    @idg.send(:probe=, type, nil, nil,
              @idg.default_probe_frequency,
              @idg.default_probe_retry_up,
              @idg.default_probe_retry_down,
              nil,
              @idg.default_probe_timeout)
    assert_equal(@idg.default_probe_frequency, @idg.probe_frequency)
    assert_equal(@idg.default_probe_timeout, @idg.probe_timeout)
    assert_equal(@idg.default_probe_retry_up, @idg.probe_retry_up)
    assert_equal(@idg.default_probe_retry_down, @idg.probe_retry_down)
    @idg.send(:probe=, @idg.default_probe_type,
              nil, nil, nil, nil, nil, nil, nil)
    assert_equal(@idg.default_probe_type, @idg.probe_type)
    @idg.destroy
  end
end
