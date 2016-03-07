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

# TestEncapsulation - Minitest for Encapsulation node utility class
class TestEncapsulation < CiscoTestCase
  @skip_unless_supported = 'encapsulation'
  @@cleaned = false # rubocop:disable Style/ClassVars

  def cleanup
    Encapsulation.encaps.each do |_encap, obj|
      obj.destroy
    end
  end

  def setup
    # setup runs at the beginning of each test
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    # teardown runs at the end of each test
    super
    cleanup
  end

  # TESTS

  def test_encapsulation_create_destroy
    encap = Encapsulation.new('cisco')
    encap.destroy
  end

  def test_encapsulation_dot1_mapping
    encap = Encapsulation.new('cisco')
    assert_equal(encap.default_dot1q_map, encap.dot1q_map,
                 'Error: dot1q is not matching')
    dot1q = '100-110'
    vni = '5000-5010'
    encap.send(:set_dot1q_map=, true, dot1q, vni)
    assert_equal(dot1q, encap.dot1q_map[0].gsub(/\s+/, ''),
                 'Error: dot1q is not matching')
    assert_equal(vni, encap.dot1q_map[1].gsub(/\s+/, ''),
                 'Error: vni to dot1q mapping is not matchin')
    encap.destroy
  end

  def test_invalid_range_dot1q_mapping
    encap = Encapsulation.new('cisco')
    assert_equal(encap.default_dot1q_map, encap.dot1q_map,
                 'Error: dot1q is not matching')
    dot1q = '100-111'
    vni = '5000-5010'
    assert_raises(RuntimeError,
                  'Encap misconfig did not raise RuntimeError') do
      encap.send(:set_dot1q_map=, true, dot1q, vni)
    end
  end
end
