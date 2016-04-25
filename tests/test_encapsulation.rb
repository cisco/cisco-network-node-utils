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
require_relative '../lib/cisco_node_utils/encapsulation'
require_relative '../lib/cisco_node_utils/vdc'

# TestEncapsulation - Minitest for Encapsulation node utility class
class TestEncapsulation < CiscoTestCase
  @skip_unless_supported = 'encapsulation'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    return unless @@pre_clean_needed

    # This provider requires MT-Full and a compatible linecard
    mt_full_interface?
    Vdc.new('default').limit_resource_module_type = 'f3'
    cleanup
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
    super
  end

  def cleanup
    config_no_warn('no feature vni')
    Encapsulation.encaps.each do |_encap, obj|
      obj.destroy
    end
  end

  # TESTS

  def test_create_destroy
    profile = 'cisco'
    e = Encapsulation.new(profile)
    assert(Encapsulation.encaps[profile], "profile '#{profile}' not found")
    e.destroy
  end

  def test_dot1q_map
    e = Encapsulation.new('cisco')
    assert_equal(e.default_dot1q_map, e.dot1q_map)

    map = ['100-110,150', '5000-5010,5050']
    e.dot1q_map = map
    assert_equal(map, e.dot1q_map)

    e.dot1q_map = e.default_dot1q_map
    assert_equal(e.default_dot1q_map, e.dot1q_map)

    e.destroy
  end

  def test_dot1q_map_negative
    e = Encapsulation.new('cisco')
    assert_raises(CliError) do
      # Test for range imbalance (3 vlans to only 2 vnis)
      e.dot1q_map = ['101-103', '5101-5102']
    end
  end
end
