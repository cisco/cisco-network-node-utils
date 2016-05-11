#!/usr/bin/env ruby
# cisco_cmn_utils Unit Tests
#
# Chris Van Heuveln, May, 2016
#
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
require_relative '../lib/cisco_node_utils/cisco_cmn_utils'

# Test utility methods in cisco_cmn_utils
class TestCmnUtils < CiscoTestCase
  #
  # TBD: Add tests for *all* methods in cisco_cmn_utils
  #
  def test_dash_range_to_ruby_range
    expected = [2..5, 9..9, 4..6]

    str_input = '2-5, 9, 4-6'
    assert_equal(expected, Utils.dash_range_to_ruby_range(str_input))

    arr_input = ['2-5', '9', '4-6']
    assert_equal(expected, Utils.dash_range_to_ruby_range(arr_input))
  end

  def test_ruby_range_to_dash_range
    str_expected = '2-5, 9, 4-6'
    arr_expected = ['2-5', '9', '4-6']

    input1 = [2..5, 9..9, 4..6]
    input2 = input1.clone
    assert_equal(str_expected, Utils.ruby_range_to_dash_range(input1, :string))
    assert_equal(arr_expected, Utils.ruby_range_to_dash_range(input2, :array))
  end

  def test_dash_range_to_elements
    expected = %w(2 3 4 5 6 9)

    str_input = '2-5, 9, 4-6'
    str_arr_input = ['2-5, 9, 4-6']
    arr_input = str_input.split(', ')

    assert_equal(expected, Utils.dash_range_to_elements(str_input))
    assert_equal(expected, Utils.dash_range_to_elements(str_arr_input))
    assert_equal(expected, Utils.dash_range_to_elements(arr_input))
  end

  def test_merge_range
    expected = [2..6, 9..9]
    input = [2..5, 9..9, 4..6]
    assert_equal(expected, Utils.merge_range(input))
  end

  def test_normalize_range_array
    expected = ['2-6', '9']

    str_input = '2-5, 9, 4-6'
    str_arr_input = ['2-5, 9, 4-6']
    arr_input = str_input.split(', ')
    assert_equal(expected, Utils.normalize_range_array(str_input))
    assert_equal(expected, Utils.normalize_range_array(str_arr_input))
    assert_equal(expected, Utils.normalize_range_array(arr_input))
  end
end
