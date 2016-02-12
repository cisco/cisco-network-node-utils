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
#-----------------------------------------------------------
# CLI: <afi> pim rp-address <rp-address> group-list <group>
#      (under different VRFs)
#-----------------------------------------------------------
# Testcases: All Tests create and destroy all instances within a test
#
# 1. test_all_group_lists
#
# 2. test_single_rpaddr_single_invalid_grouplist_single_vrf:
#         vrf default, ip pim rp-address 25.25.25.25 group-list 25.0.0.0/8
#-------------------------------------------------------------------------------

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/pim_group_list'

include Cisco

# TestPim - Minitest for PimGrouplist
class TestPimGroupList < CiscoTestCase
  # Enables feature pim
  #--------------------
  def setup
    super
    config('no feature pim')
  end

  # Test Pim.group_lists
  # - multiple vrfs, groups, rp_addrs
  # - same rp_addr, different group
  # - same rp_addr, different vrf
  # - same group, different rp_addr
  # - same group, different vrf
  #--------------------------------------------
  def all_group_lists(afi)
    rp_addr1 = '11.11.11.11'
    rp_addr2 = '22.22.22.22'
    grouplist1 = '227.0.0.0/8'
    grouplist2 = '228.0.0.0/8'

    # Basic setup
    vrf = 'default'
    pd1 = PimGroupList.new(afi, vrf, rp_addr1, grouplist1)
    pd2 = PimGroupList.new(afi, vrf, rp_addr2, grouplist2)
    hash = PimGroupList.group_lists
    assert(hash.key?(afi))
    assert(hash[afi].key?(vrf))
    assert_equal(2, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 2 group lists")
    assert(hash[afi][vrf].key?([rp_addr1, grouplist1]),
           "hash[#{afi}][#{vrf}] does not contain [#{rp_addr1}, #{grouplist1}]")
    assert(hash[afi][vrf].key?([rp_addr2, grouplist2]),
           "hash[#{afi}][#{vrf}] does not contain [#{rp_addr2}, #{grouplist2}]")

    # vrf with same rp_addrs/groups as in default
    vrf = 'red'
    pd3 = PimGroupList.new(afi, vrf, rp_addr1, grouplist1)
    pd4 = PimGroupList.new(afi, vrf, rp_addr2, grouplist2)
    hash = PimGroupList.group_lists
    assert_equal(2, hash[afi].keys.count,
                 "hash[#{afi}] does not have 2 vrfs")
    assert(hash[afi].key?(vrf))
    assert_equal(2, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 2 group lists")
    assert(hash[afi][vrf].key?([rp_addr1, grouplist1]),
           "hash[#{afi}][#{vrf}] does not contain [#{rp_addr1}, #{grouplist1}]")
    assert(hash[afi][vrf].key?([rp_addr2, grouplist2]),
           "hash[#{afi}][#{vrf}] does not contain [#{rp_addr2}, #{grouplist2}]")

    # different vrf, same rps / diff groups, etc.
    vrf = 'black'
    rp_addr7 = '7.7.7.7'
    pd5 = PimGroupList.new(afi, vrf, rp_addr1, grouplist1)
    pd6 = PimGroupList.new(afi, vrf, rp_addr1, grouplist2)
    pd7 = PimGroupList.new(afi, vrf, rp_addr7, grouplist2)
    hash = PimGroupList.group_lists
    assert_equal(3, hash[afi].keys.count,
                 "hash[#{afi}] does not have 3 vrfs")
    assert(hash[afi].key?(vrf))
    assert_equal(3, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 3 group lists")
    assert(hash[afi][vrf].key?([rp_addr1, grouplist1]),
           "hash[#{afi}][#{vrf}] does not contain [#{rp_addr1}, #{grouplist2}]")
    assert(hash[afi][vrf].key?([rp_addr1, grouplist2]),
           "hash[#{afi}][#{vrf}] does not contain [#{rp_addr1}, #{grouplist2}]")
    assert(hash[afi][vrf].key?([rp_addr7, grouplist2]),
           "hash[#{afi}][#{vrf}] does not contain [#{rp_addr7}, #{grouplist2}]")

    # Test removal
    vrf = 'default'
    pd1.destroy
    hash = PimGroupList.group_lists
    assert_equal(1, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 1 group lists")
    refute(hash[afi][vrf].key?([rp_addr1, grouplist1]),
           "hash[#{afi}][#{vrf}] should not contain "\
           "[#{rp_addr1}, #{grouplist1}]")

    vrf = 'red'
    pd3.destroy
    hash = PimGroupList.group_lists
    assert_equal(1, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 1 group lists")
    refute(hash[afi][vrf].key?([rp_addr1, grouplist1]),
           "hash[#{afi}][#{vrf}] should not contain "\
           "[#{rp_addr1}, #{grouplist1}]")

    vrf = 'black'
    pd5.destroy
    pd7.destroy
    hash = PimGroupList.group_lists
    assert_equal(1, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 1 group lists")
    refute(hash[afi][vrf].key?([rp_addr1, grouplist1]),
           "hash[#{afi}][#{vrf}] should not contain "\
           "[#{rp_addr1}, #{grouplist1}]")
    pd2.destroy
    pd4.destroy
    pd6.destroy
    hash = PimGroupList.group_lists
    assert_empty(hash[afi], 'hash[#{afi}] is not empty')
  end

  # Tests Pim.group_lists
  #------------------------------------------
  def test_all_group_lists
    %w(ipv4).each do |afi|
      all_group_lists(afi)
    end
  end

  # Creates single invalid rp address single grouplist vrf default
  #---------------------------------------------------------------
  def create_single_invalid_rpaddr_single_grouplist_single_vrf(afi)
    rp_addr = '256.256.256.256'
    grouplist = '224.0.0.0/8'
    assert_raises(CliError) do
      PimGroupList.new(afi, 'default', rp_addr, grouplist)
    end
  end

  # Tests single invalid rp address single grouplist vrf default
  #---------------------------------------------------------------
  def test_single_invalid_rpaddr_single_grouplist_single_vrf
    %w(ipv4).each do |afi|
      create_single_invalid_rpaddr_single_grouplist_single_vrf(afi)
    end
  end

  # Creates single rp address single invalid grouplist single vrf
  #---------------------------------------------------------------
  def create_single_rpaddr_single_invalid_grouplist_single_vrf(afi)
    rp_addr = '25.25.25.25'
    grouplist = '25.0.0.0/8'
    assert_raises(CliError) do
      PimGroupList.new(afi, 'red', rp_addr, grouplist)
    end
  end

  # Tests single rp address single invalid grouplist single vrf
  #---------------------------------------------------------------
  def test_single_rpaddr_single_invalid_grouplist_single_vrf
    %w(ipv4).each do |afi|
      create_single_rpaddr_single_invalid_grouplist_single_vrf(afi)
    end
  end
end
