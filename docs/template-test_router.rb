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
require File.expand_path('../../lib/cisco_node_utils/router_X__RESOURCE_NAME__X',
                         __FILE__)

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestX__CLASS_NAME__X < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_feature_X__RESOURCE_NAME__X
  end

  def teardown
    # teardown runs at the end of each test
    no_feature_X__RESOURCE_NAME__X
    super
  end

  def no_feature_X__RESOURCE_NAME__X
    # Turn the feature off for a clean test.
    @device.cmd('conf t ; no feature X__RESOURCE_NAME__X ; end')
    # Flush the cache since we've modified the device outside of
    # the node_utils APIs
    node.cache_flush
  end

  # TESTS

  def test_router_create_destroy_one
    id = 'blue'
    rtr = X__CLASS_NAME__X.new(id)
    s = @device.cmd("show runn | i 'router X__RESOURCE_NAME__X #{id}'")
    assert_match(s, /^router X__RESOURCE_NAME__X #{id}$/,
                 "Error: failed to create router X__RESOURCE_NAME__X #{id}")

    rtr.destroy
    s = @device.cmd("show runn | i 'router X__RESOURCE_NAME__X #{id}'")
    refute_match(s, /^router X__RESOURCE_NAME__X #{id}$/,
                 "Error: failed to destroy router X__RESOURCE_NAME__X #{id}")

    s = @device.cmd("show runn | i 'feature X__RESOURCE_NAME__X'")
    refute_match(s, /^feature X__RESOURCE_NAME__X$/,
                 'Error: failed to disable feature X__RESOURCE_NAME__X')
  end

  def test_router_create_destroy_multiple
    id1 = 'blue'
    rtr1 = X__CLASS_NAME__X.new(id1)
    id2 = 'red'
    rtr2 = X__CLASS_NAME__X.new(id2)

    s = @device.cmd("show runn | i 'router X__RESOURCE_NAME__X'")
    assert_match(s, /^router X__RESOURCE_NAME__X #{id1}$/)
    assert_match(s, /^router X__RESOURCE_NAME__X #{id2}$/)

    rtr1.destroy
    s = @device.cmd("show runn | i 'router X__RESOURCE_NAME__X #{id1}'")
    refute_match(s, /^router X__RESOURCE_NAME__X #{id1}$/,
                 "Error: failed to destroy router X__RESOURCE_NAME__X #{id1}")

    rtr2.destroy
    s = @device.cmd("show runn | i 'router X__RESOURCE_NAME__X #{id2}'")
    refute_match(s, /^router X__RESOURCE_NAME__X #{id2}$/,
                 "Error: failed to destroy router X__RESOURCE_NAME__X #{id2}")

    s = @device.cmd("show runn | i 'feature X__RESOURCE_NAME__X'")
    refute_match(s, /^feature X__RESOURCE_NAME__X$/,
                 'Error: failed to disable feature X__RESOURCE_NAME__X')
  end

  def test_router_X__PROPERTY_INT__X
    id = 'blue'
    rtr = X__CLASS_NAME__X.new(id)
    val = 5 # This value depends on property bounds
    rtr.X__PROPERTY_INT__X = val
    assert_equal(rtr.X__PROPERTY_INT__X, val, "X__PROPERTY_INT__X is not #{val}")

    # Get default value from yaml
    val = node.config_get_default('X__RESOURCE_NAME__X', 'X__PROPERTY_INT__X')
    rtr.X__PROPERTY_INT__X = val
    assert_equal(rtr.X__PROPERTY_INT__X, val, "X__PROPERTY_INT__X is not #{val}")
  end

  def test_router_X__PROPERTY_BOOL__X
    id = 'blue'
    rtr = X__CLASS_NAME__X.new(id)
    rtr.X__PROPERTY_BOOL__X = true
    assert(rtr.X__PROPERTY_BOOL__X, 'X__PROPERTY_BOOL__X state is not true')

    rtr.X__PROPERTY_BOOL__X = false
    refute(rtr.X__PROPERTY_BOOL__X, 'X__PROPERTY_BOOL__X state is not false')
  end
end
