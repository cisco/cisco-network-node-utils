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

    global.key_set('44444444', nil)
    assert_equal(Cisco::RadiusGlobal.radius_global[id].key,
                 '44444444')
    assert_equal(global.key,
                 '44444444')

    # Setting back to default and re-checking
    global.timeout = global.default_timeout
    global.retransmit_count = global.default_retransmit_count
    assert_equal(global.timeout, global.default_timeout)
    assert_equal(global.retransmit_count, global.default_retransmit_count)
  end
end
