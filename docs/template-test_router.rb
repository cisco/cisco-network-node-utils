# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/router___RESOURCE_NAME__', __FILE__)

# Test__CLASS_NAME__ - Minitest for __CLASS_NAME__ node utility class
class Test__CLASS_NAME__ < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_feature___RESOURCE_NAME__
  end

  def teardown
    # teardown runs at the end of each test
    no_feature___RESOURCE_NAME__
    super
  end

  def no_feature___RESOURCE_NAME__
    # Turn the feature off for a clean test.
    @device.cmd('conf t ; no feature __RESOURCE_NAME__ ; end')
    # Flush the cache since we've modified the device outside of the node_utils APIs
    node.cache_flush
  end

  # TESTS

  def test_router_create_destroy_one
    id = 'blue'
    rtr = __CLASS_NAME__.new(id)
    s = @device.cmd("show runn | i 'router __RESOURCE_NAME__ #{id}'")
    assert_match(s, /^router __RESOURCE_NAME__ #{id}$/,
                 "Error: failed to create router __RESOURCE_NAME__ #{id}")

    rtr.destroy
    s = @device.cmd("show runn | i 'router __RESOURCE_NAME__ #{id}'")
    refute_match(s, /^router __RESOURCE_NAME__ #{id}$/,
                 "Error: failed to destroy router __RESOURCE_NAME__ #{id}")

    s = @device.cmd("show runn | i 'feature __RESOURCE_NAME__'")
    refute_match(s, /^feature __RESOURCE_NAME__$/,
                 'Error: failed to disable feature __RESOURCE_NAME__')
  end

  def test_router_create_destroy_multiple
    id1 = 'blue'
    rtr1 = __CLASS_NAME__.new(id1)
    id2 = 'red'
    rtr2 = __CLASS_NAME__.new(id2)

    s = @device.cmd("show runn | i 'router __RESOURCE_NAME__'")
    assert_match(s, /^router __RESOURCE_NAME__ #{id1}$/)
    assert_match(s, /^router __RESOURCE_NAME__ #{id2}$/)

    rtr1.destroy
    s = @device.cmd("show runn | i 'router __RESOURCE_NAME__ #{id1}'")
    refute_match(s, /^router __RESOURCE_NAME__ #{id1}$/,
                 "Error: failed to destroy router __RESOURCE_NAME__ #{id1}")

    rtr2.destroy
    s = @device.cmd("show runn | i 'router __RESOURCE_NAME__ #{id2}'")
    refute_match(s, /^router __RESOURCE_NAME__ #{id2}$/,
                 "Error: failed to destroy router __RESOURCE_NAME__ #{id2}")

    s = @device.cmd("show runn | i 'feature __RESOURCE_NAME__'")
    refute_match(s, /^feature __RESOURCE_NAME__$/,
                 'Error: failed to disable feature __RESOURCE_NAME__')
  end

  def test_router___PROPERTY_INT__
    id = 'blue'
    rtr = __CLASS_NAME__.new(id)
    val = 5 # This value depends on property bounds
    rtr.__PROPERTY_INT__ = val
    assert_equal(rtr.__PROPERTY_INT__, val, "__PROPERTY_INT__ is not #{val}")

    # Get default value from yaml
    val = node.config_get_default('__RESOURCE_NAME__', '__PROPERTY_INT__')
    rtr.__PROPERTY_INT__ = val
    assert_equal(rtr.__PROPERTY_INT__, val, "__PROPERTY_INT__ is not #{val}")
  end

  def test_router___PROPERTY_BOOL__
    id = 'blue'
    rtr = __CLASS_NAME__.new(id)
    rtr.__PROPERTY_BOOL__ = true
    assert(rtr.__PROPERTY_BOOL__, '__PROPERTY_BOOL__ state is not true')

    rtr.__PROPERTY_BOOL__ = false
    refute(rtr.__PROPERTY_BOOL__, '__PROPERTY_BOOL__ state is not false')
  end
end
