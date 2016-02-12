# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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
# CLI: <afi> pim ssm-range <range>  (under different VRFs)
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
require_relative '../lib/cisco_node_utils/pim'

include Cisco

# TestPim - Minitest for Pim Feature
class TestPim < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  # Enables feature pim
  #---------------------
  def setup
    super
    remove_all_pims if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    super
    remove_all_pims
  end

  def remove_all_pims
    Pim.pims.each do |_afi, vrfs|
      vrfs.each do |_vrf, obj|
        obj.destroy
      end
    end
  end

  # Creates single ssm range under default vrf
  #-----------------------------------------------
  def create_single_ssm_range_single_vrf(afi)
    range = '229.0.0.0/8'
    p1 = Pim.new(afi, 'default')
    p1.ssm_range = (range)
    assert_equal(p1.ssm_range.split.sort.join(' '), range.split.sort.join(' '))
  end

  # Tests single ssm range none under default vrf
  #-----------------------------------------------
  def test_single_ssm_range_single_vrf
    %w(ipv4).each do |afi|
      create_single_ssm_range_single_vrf(afi)
    end
  end

  # Creates single ssm range none under default vrf
  #-----------------------------------------------
  def create_single_ssm_range_none_single_vrf(afi)
    range = 'none'
    p1 = Pim.new(afi, 'default')
    p1.ssm_range = (range)
    assert_equal(p1.ssm_range.split.sort.join(' '), range.split.sort.join(' '))
  end

  # Tests single ssm range none under default vrf
  #-----------------------------------------------
  def test_single_ssm_range_none_single_vrf
    %w(ipv4).each do |afi|
      create_single_ssm_range_none_single_vrf(afi)
    end
  end

  # Creates multiple ssm ranges under different vrfs
  #-----------------------------------------------
  def create_multiple_ssm_range_multiple_vrfs(afi)
    range1 = '229.0.0.0/8 225.0.0.0/8 224.0.0.0/8'
    range2 = '230.0.0.0/8 228.0.0.0/8 224.0.0.0/8'
    range3 = 'none'
    p1 = Pim.new(afi, 'default')
    p2 = Pim.new(afi, 'red')
    p3 = Pim.new(afi, 'black')
    p1.ssm_range = (range1)
    p2.ssm_range = (range2)
    p3.ssm_range = (range3)
    assert_equal(p1.ssm_range.split.sort.join(' '), range1.split.sort.join(' '))
    assert_equal(p2.ssm_range.split.sort.join(' '), range2.split.sort.join(' '))
    assert_equal(p3.ssm_range.split.sort.join(' '), range3.split.sort.join(' '))
  end

  # Tests multiple ssm ranges under different vrfs
  #-----------------------------------------------
  def test_multiple_ssm_range_multiple_vrfs
    %w(ipv4).each do |afi|
      create_multiple_ssm_range_multiple_vrfs(afi)
    end
  end

  # Creates multiple ssm ranges overwrite under different vrfs
  #-----------------------------------------------
  def create_multiple_ssm_range_overwrite_multiple_vrfs(afi)
    range1 = '229.0.0.0/8 225.0.0.0/8 224.0.0.0/8'
    range2 = '230.0.0.0/8 228.0.0.0/8 224.0.0.0/8'
    range3 = 'none'
    p1 = Pim.new(afi, 'default')
    p2 = Pim.new(afi, 'red')
    p1.ssm_range = (range1)
    p2.ssm_range = (range2)
    assert_equal(p1.ssm_range.split.sort.join(' '), range1.split.sort.join(' '))
    assert_equal(p2.ssm_range.split.sort.join(' '), range2.split.sort.join(' '))
    p2.ssm_range = (range3)
    assert_equal(p2.ssm_range.split.sort.join(' '), range3.split.sort.join(' '))

    p1.destroy
    assert('none', p1.ssm_range)

    p2.destroy
    assert('none', p2.ssm_range)
  end

  # Tests multiple ssm ranges overwrite under different vrfs
  #-----------------------------------------------
  def test_multiple_ssm_range_overwrite_multiple_vrfs
    %w(ipv4).each do |afi|
      create_multiple_ssm_range_overwrite_multiple_vrfs(afi)
    end
  end

  # Creates single invalid ssm range under vrf default
  #---------------------------------------------------
  def create_single_invalid_ssm_range_single_vrf(afi)
    range = '1.1.1.1/8'
    p1 = Pim.new(afi, 'default')
    assert_raises(CliError) do
      p1.ssm_range = (range)
    end
  end

  # Tests single invalid ssm range under vrf default
  #---------------------------------------------------
  def test_single_invalid_ssm_range_single_vrf
    %w(ipv4).each do |afi|
      create_single_invalid_ssm_range_single_vrf(afi)
    end
  end
end
