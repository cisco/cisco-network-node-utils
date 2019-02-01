#
# Minitest for RadiusGlobal class
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/radius_global'

# TestRadiusGlobal - Minitest for RadiusGlobal node utility.
class TestRadiusGlobal < CiscoTestCase
  @skip_unless_supported = 'radius_global'

  def setup
    # setup runs at the beginning of each test
    super
    no_radius_global
  end

  def teardown
    # teardown runs at the end of each test
    no_radius_global
    super
  end

  def no_radius_global
    # Turn the feature off for a clean test.
    config('no radius-server timeout 2',
           'no radius-server retransmit 3')
  end

  # TESTS

  def test_radius_global
    id = 'default'

    global = Cisco::RadiusGlobal.new(id)
    assert_includes(Cisco::RadiusGlobal.radius_global, id)
    assert_equal(Cisco::RadiusGlobal.radius_global[id], global)

    # Default Checking
    assert_equal(global.timeout, global.default_timeout)
    assert_equal(global.retransmit_count, global.default_retransmit_count)

    global.retransmit_count = 3
    assert_equal(Cisco::RadiusGlobal.radius_global[id].retransmit_count,
                 3)
    assert_equal(global.retransmit_count,
                 3)

    global.timeout = 2
    assert_equal(Cisco::RadiusGlobal.radius_global[id].timeout,
                 2)
    assert_equal(global.timeout,
                 2)

    if platform == :nexus
      key = 'aaaAAAGGTTYTYY 44444444 72'
      global.key_set(key, 7)
      assert_match(/#{key}/, global.key)
      assert_match(/#{key}/, Cisco::RadiusGlobal.radius_global[id].key)
      assert_equal(7, global.key_format)
      unless Platform.image_version[/I2|I4/] # legacy defect CSCvb57180
        # Change to type 6
        key = 'JDYkqyIFWeBvzpljSfWmRZrmRSRE8'
        global.key_set(key, 6)
        assert_match(/#{key}/, global.key)
        assert_equal(6, global.key_format)
      end
    elsif platform == :ios_xr
      global.key_set('QsEfThUkO', nil)
      assert(!global.key.nil?)
      assert(!Cisco::RadiusGlobal.radius_global[id].key.nil?)
    end

    # Setting back to default and re-checking
    global.timeout = nil
    global.retransmit_count = nil
    global.key_set(nil, nil)
    assert_equal(global.timeout, global.default_timeout)
    assert_equal(global.retransmit_count, global.default_retransmit_count)
    assert_nil(global.key)

    # Default source interface
    global.source_interface = global.default_source_interface
    assert_nil(global.source_interface)

    # Set source interface
    interface = 'loopback0'
    global.source_interface = interface
    assert_equal(interface, global.source_interface)

    # Remove source interface
    global.source_interface = nil
    assert_nil(global.source_interface)
  end
end
