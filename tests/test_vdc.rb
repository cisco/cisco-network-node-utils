# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/vdc'

include Cisco

# TestVdc - Minitest for general functionality of the Vdc class.
class TestVdc < CiscoTestCase
  # This test suite currently has very limited use because:
  #  a) VDC support is limited to a narrow list of platforms.
  #  b) License restrictions may limit platforms to a single vdc
  #  c) Linecard restrictions may limit some tests to specific linecards

  def setup
    super
    # Check for supported platform
    skip('Platform does not support VDCs') unless Vdc.vdc_support
  end

  def test_all_vdcs
    # This test is limited because our vdc provider does not yet support
    # vdc creation. For now just check that we get a non-empty list and
    # that it at least contains the default vdc.
    v = Vdc.vdcs
    refute_empty(v.keys, 'vdc hash should have at least one vdc')
    assert(v.key?(Vdc.default_vdc_name), 'default vdc name not found')
  end

  def test_create
    assert_raises(ArgumentError) do
      Vdc.new('non_def', 'Currently no support for non-default VDCs')
    end
  end

  def compatible_interface?
    # MT-full tests require a specific linecard; either because they need a
    # compatible interface or simply to enable the features. Either way
    # we will provide an appropriate interface name if the linecard is present.
    # Example 'show mod' output to match against:
    #   '9  12  10/40 Gbps Ethernet Module  N7K-F312FQ-25 ok'
    sh_mod = @device.cmd("sh mod | i '^[0-9]+.*N7K-F3'")[/^(\d+)\s.*N7K-F3/]
    slot = sh_mod.nil? ? nil : Regexp.last_match[1]
    skip('Unable to find compatible interface in chassis') if slot.nil?

    "ethernet#{slot}/1"
  end

  def test_limit_resource_module_type
    compatible_interface?
    v = Vdc.new('default')
    # Set limit-resource module-type to default (this is variable for each
    # device, so the default is for this device only)
    v.limit_resource_module_type = ''
    default = v.limit_resource_module_type

    # Limit to F3 cards only
    type = 'f3'
    v.limit_resource_module_type = type
    assert_equal(type, v.limit_resource_module_type)

    # Reset to device-default
    v.limit_resource_module_type = ''
    assert_equal(default, v.limit_resource_module_type)
  end
end
