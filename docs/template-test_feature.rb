#
# Minitest for __CLASS_NAME__ class
#
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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/__RESOURCE_NAME__", __FILE__)

class Test__CLASS_NAME__ < CiscoTestCase

  def setup
    # setup automatically runs at the beginning of each test
    super
    no_feature
  end

  def teardown
    # teardown automatically runs at the end of each test
    no_feature
    super
  end

  def no_feature
    # setup/teardown helper. Turn the feature off for a clean testbed.
    @device.cmd("conf t ; no feature __CLI_NAME__ ; end")
    # Flush the cache since we've modified the device outside of the node_utils APIs
    node.cache_flush()
  end

  # TESTS

  def test_feature_on
    feat = __CLASS_NAME__.new()
    assert(feat.feature_enabled)
  end

  def test_feature_off
    feat = __CLASS_NAME__.new()
    feat.feature_disable
    refute(feat.feature_enabled)
  end
end
