# Copyright (c) 2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/vdc'
require_relative '../lib/cisco_node_utils/vxlan_vtep'

include Cisco

# TestVlanMtFull - Minitest for Vlan node utility (MT-Full testing only)
#
# This test requires specific platform & linecard support:
#   - vdc support with 'limit-resource module-type' set to 'f3'
#
class TestVlanMtFull < CiscoTestCase
  @@cleaned = false # rubocop:disable Style/ClassVars
  def cleanup
    Vlan.vlans.each do |vlan, obj|
      # skip reserved vlans
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      obj.destroy
    end
    interface_ethernet_default(interfaces[0])
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
  end

  def interface_ethernet_default(ethernet_id)
    config("default interface ethernet #{ethernet_id}")
  end

  def mt_full_env_setup
    skip('Platform does not support MT-full') unless VxlanVtep.mt_full_support
    mt_full_interface?
    v = Vdc.new('default')
    v.limit_resource_module_type = 'f3' unless
      v.limit_resource_module_type == 'f3'
  end

  def test_vlan_mode_fabricpath
    mt_full_env_setup

    # Test for valid mode
    v = Vlan.new(2000)
    assert_equal('ce', v.mode,
                 'Mode should have been default to ce')
    v.mode = 'fabricpath'
    assert_equal(:enabled, v.fabricpath_feature,
                 'Fabricpath feature should have been enabled')
    assert_equal('fabricpath', v.mode,
                 'Mode should have been set to fabricpath')

    # Test for invalid mode
    v = Vlan.new(100)
    assert_equal('ce', v.mode,
                 'Mode should have been default to ce')

    assert_raises(RuntimeError) { v.mode = 'junk' }
  end
end
