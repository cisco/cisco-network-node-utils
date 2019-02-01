#
# Minitest for TacacsGlobal class
#
# Copyright (c) 2014-2017 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/tacacs_global'

# TestTacacsGlobal - Minitest for TacacsGlobal node utility.
class TestTacacsGlobal < CiscoTestCase
  @skip_unless_supported = 'tacacs_global'

  def setup
    # setup runs at the beginning of each test
    super
    config_no_warn('no feature tacacs+') if platform == :nexus
    no_tacacs_global if platform == :ios_xr
  end

  def teardown
    # teardown runs at the end of each test
    no_tacacs_global if platform == :ios_xr
    config_no_warn('no feature tacacs+') if platform == :nexus
    super
  end

  def no_tacacs_global
    # Turn the feature off for a clean test.
    config('no tacacs-server timeout 2')
  end

  # TESTS

  def test_tacacs_global
    id = 'default'

    global = Cisco::TacacsGlobal.new(id)
    assert_includes(Cisco::TacacsGlobal.tacacs_global, id)
    assert_equal(global, Cisco::TacacsGlobal.tacacs_global[id])

    # No timeout when TACACS is not enabled
    assert_nil(global.timeout)

    # Turn on TACACS and verify default Timeout
    config_no_warn('feature tacacs+') if platform == :nexus
    assert_equal(global.default_timeout, global.timeout)

    # Timeout update
    global.timeout = 10
    assert_equal(10, Cisco::TacacsGlobal.tacacs_global[id].timeout)
    assert_equal(10, global.timeout)

    # Do not unset timout if TACACS is enabled
    assert_raises(ArgumentError) do
      global.timeout = nil
    end

    # Check there is no default key
    assert_equal('', global.key)

    # first key change - unencrypted key
    key = 'TEST_NEW'
    global.encryption_key_set(nil, key)
    # Device encypts key - verify return value
    assert_equal(7, global.key_format)
    key = 'WAWY_NZB'
    assert_equal(key, global.key)

    skip_versions = ['7.0.3.(I2|I3)', '7.0.3.I4.[1-7]']
    if step_unless_legacy_defect(skip_versions, 'CSCvh72911: Cannot configure tacacs-server key 6')
      # second key change - modify key to type6
      key_format = 6
      # Must use a valid type6 password: CSCvb36266
      key = 'JDYkqyIFWeBvzpljSfWmRZrmRSRE8'
      global.encryption_key_set(key_format, key)
      assert_equal(key_format, global.key_format)

      assert_equal(key, global.key)
    end

    # Remove global key
    global.encryption_key_set('', '')
    assert_equal('', global.key)

    # Default source interface
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
