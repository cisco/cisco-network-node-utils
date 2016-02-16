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
require_relative '../lib/cisco_node_utils/private_vlan'

# TestVtp - Minitest for PrivateVlan node utility class
class TestPrivateVlan < CiscoTestCase
  def setup
    super
    no_feature_private_vlan
  end

  def teardown
    no_feature_private_vlan
    super
  end

  def no_feature_private_vlan
    config('no feature private-vlan')
  end

  def test_private_vlan_feature_enable_disable
    privatevlan = PrivateVlan.new
    privatevlan.feature_enable
    assert(PrivateVlan.feature_enabled)

    privatevlan.feature_disable
    assert(PrivateVlan.feature_enabled, 'Feature not disabled')
  end
end
