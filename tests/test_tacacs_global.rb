#
# Minitest for TacacsGlobal class
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
    no_tacacs_global
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

    # Default Checking
    assert_equal(global.default_timeout, global.timeout)

    global.timeout = 5
    assert_equal(5, Cisco::TacacsGlobal.tacacs_global[id].timeout)
    assert_equal(5, global.timeout)

    # first change
    key_format = 0
    key = 'TEST_NEW'
    global.encryption_key_set(key_format, key)
    assert(!global.key.nil?)
    assert(key_format, global.key_format)

    # second change
    key_format = 6

    # Must use a valid type6 password: CSCvb36266
    key = 'JDYkqyIFWeBvzpljSfWmRZrmRSRE8'
    global.encryption_key_set(key_format, key)
    assert(!global.key.nil?)
    assert(key_format, global.key_format)

    # Setting back to default and re-checking
    global.timeout = global.default_timeout
    assert_equal(global.default_timeout, global.timeout)
  end
end
