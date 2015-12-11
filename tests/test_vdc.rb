# Copyright (c) 2015 Cisco and/or its affiliates.
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
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vdc', 'all_vdcs').config_get_token.nil?
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

  def test_limit_resource_module_type
    # This test requires a specific linecard; as such we will hard-code the
    # module location and skip the test if not found.
    # Example 'show mod' output to match against:
    # '9    12     10/40 Gbps Ethernet Module          N7K-F312FQ-25      ok'
    slot = 9
    pat = Regexp.new("^#{slot}\s.*N7K-F3")
    skip("Test requires N7K-F3 linecard in slot #{slot}") unless
      @device.cmd('sh mod | i N7K-F').match(pat)

    v = Vdc.new('default')
    v.limit_resource_module_type_f3 = false
    refute(v.limit_resource_module_type_f3)

    v.limit_resource_module_type_f3 = true
    assert(v.limit_resource_module_type_f3)

    v.limit_resource_module_type_f3 = v.default_limit_resource_module_type_f3
    assert_equal(v.default_limit_resource_module_type_f3,
                 v.limit_resource_module_type_f3)
  end
end
