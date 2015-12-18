# Copyright (c) 2013-2015 Cisco and/or its affiliates.
#
# Smitha Gopalan, November 2015
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
#-------------------------------------------------------------------------------
# CLI: ip pim ssm-range <range>  (under different VRFs)
#-------------------------------------------------------------------------------
# Testcases: All Tests create all instances within a test
# 1. test_single_ssm_range_single_vrf:
#         vrf default, ip pim ssm-range 229.0.0.0/8
#
# 2. test_single_ssm_range_none_single_vrf:
#         vrf default, ip pim ssm-range none
#
# 3. test_multiple_ssm_range_multiple_vrfs:
#         vrf default, ip pim ssm-range 229.0.0.0/8 225.0.0.0/8 224.0.0.0/8
#         vrf red, ip pim ssm-range 230.0.0.0/8 228.0.0.0/8 224.0.0.0/8
#         vrf black, ip pim ssm-range none
#
# 4. test_multiple_ssm_range_overwrite_multiple_vrfs:
#         vrf default, ip pim ssm-range 229.0.0.0/8 225.0.0.0/8 224.0.0.0/8
#         vrf red, ip pim ssm-range 230.0.0.0/8 228.0.0.0/8 224.0.0.0/8 -> 
#             gets overwritten to
#         vrf red, ip pim ssm-range none
#
# 5. test_single_invalid_ssm_range_single_vrf:
#         vrf default, ip pim ssm-range 1.1.1.1/8
#-------------------------------------------------------------------------------

require_relative 'ciscotest'
require 'pp'
require_relative '../lib/cisco_node_utils/pim'

include Cisco

# TestPim - Minitest for Pim Feature
class TestPim < CiscoTestCase
  def setup
    super
    config('no feature pim')
    config('feature pim')
  end

  def teardown
#    config('no feature pim')
#    super
  end

  # Tests single ssm range under default vrf
  #-----------------------------------------------
  def test_single_ssm_range_single_vrf

    puts "test_single_ssm_range_single_vrf: "
    puts "================================"
    range = '229.0.0.0/8'
    p1 = Pim.new()
    p1.ssm_range=(range)
    assert_equal(p1.ssm_range, range.split(' ').sort)
  end

  # Tests single ssm range none under default vrf
  #-----------------------------------------------
<<<<<<< HEAD
  def test_single_ssm_range_single_vrf
    %w(ipv4).each do |afi|      
      create_single_ssm_range_single_vrf(afi)
    end
  end  
=======
  def test_single_ssm_range_none_single_vrf
>>>>>>> parent of e4346a1... NXAPI Implementation & Mini Tests for Pim

    puts "test_single_ssm_range_none_single_vrf: "
    puts "==============================="
    range = 'none'
    p1 = Pim.new()
    p1.ssm_range=(range)
    assert_equal(p1.ssm_range, range.split(' ').sort)
  end

  # Tests multiple ssm ranges under different vrfs 
  #-----------------------------------------------
  def test_multiple_ssm_range_multiple_vrfs

    puts "test_multiple_ssm_range_multiple_vrfs: "
    puts "======================================="
    range = '229.0.0.0/8 225.0.0.0/8 224.0.0.0/8'
    range2 = '230.0.0.0/8 228.0.0.0/8 224.0.0.0/8'
    range3 = 'none'
    vrf = 'red'
    vrf3 ='black'
    p1 = Pim.new()
    p2 = Pim.new(vrf)
    p3 = Pim.new(vrf3)
    p1.ssm_range=(range)
    p2.ssm_range=(range2)
    p3.ssm_range=(range3)
    assert_equal(p1.ssm_range, range.split(' ').sort)
    assert_equal(p2.ssm_range, range2.split(' ').sort)
    assert_equal(p3.ssm_range, range3.split(' ').sort)
  end
  
  # Tests multiple ssm ranges overwrite under different vrfs 
  #-----------------------------------------------
  def test_multiple_ssm_range_overwrite_multiple_vrfs

    puts "test_multiple_ssm_range_overwrite_multiple_vrfs: "
    puts "======================================="
    range = '229.0.0.0/8 225.0.0.0/8 224.0.0.0/8'
    range2 = '230.0.0.0/8 228.0.0.0/8 224.0.0.0/8'
    range3 = 'none'
    vrf = 'red'
    p1 = Pim.new()
    p2 = Pim.new(vrf)
    p1.ssm_range=(range)
    p2.ssm_range=(range2)
    assert_equal(p1.ssm_range, range.split(' ').sort)
    assert_equal(p2.ssm_range, range2.split(' ').sort)
    p2.ssm_range=(range3)
    assert_equal(p2.ssm_range, range3.split(' ').sort)
  end
  
  # Tests single invalid ssm range under vrf default
  #---------------------------------------------------
  def test_single_invalid_ssm_range_single_vrf

    puts "test_single_invalid_ssm_range_single_vrf: "
    puts "=========================================="
    range = '1.1.1.1/8'
    p1 = Pim.new()
    assert_raises(CliError ) do
      p1.ssm_range=(range)
    end
  end
end
