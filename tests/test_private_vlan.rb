# NXAPI New test for feature private-vlan
# Davide Celotto Febraury 2016
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
require_relative '../lib/cisco_node_utils/feature'

# Minitest for PrivateVlan node utility class
class TestPrivateVlan < CiscoTestCase
  def setup
    super
    feature_private_vlan
  end

  def teardown
    config('no feature private-vlan')
    super
  end

  def feature_private_vlan
    Feature.private_vlan_enable
  end

  def test_private_vlan_feature_enable_disable
    assert(Feature.private_vlan_enabled?)
  end
end
