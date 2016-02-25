# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/vlan'
require_relative '../lib/cisco_node_utils/interface'

include Cisco

# TestVlan - Minitest for Vlan node utility
class TestVlan < CiscoTestCase
  @@cleaned = false # rubocop:disable Style/ClassVars
  def cleanup
    Vlan.vlans.each do |vlan, _obj|
      # skip reserved vlans
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      # obj.destroy
    end
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
  end

  def test_private_vlan_type_primary
    v1 = Vlan.new(100)
    pv_type = 'primary'
    v1.private_vlan_type = pv_type
    assert_equal(pv_type, v1.private_vlan_type)
  end
end
