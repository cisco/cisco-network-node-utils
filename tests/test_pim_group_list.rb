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
#-----------------------------------------------------------
# CLI: <afi> pim rp-address <rp-address> group-list <group>
#      (under different VRFs)
#-----------------------------------------------------------
# Testcases: All Tests create and destroy all instances within a test
#
# 1. test_single_grouplist_single_vrf:
#         vrf default, ip pim rp-address 11.11.11.11 group-list 227.0.0.0/8
#         vrf default, ip pim rp-address 22.22.22.22 group-list 228.0.0.0/8
#         vrf default, ip pim rp-address 23.23.23.23 group-list 228.0.0.0/8
#
# 2. test_multiple_rpaddrs_multiple_vrfs:
#         vrf default, ip pim rp-address 11.11.11.11 group-list 227.0.0.0/8
#         vrf default, ip pim rp-address 12.12.12.12 group-list 228.0.0.0/8
#         vrf red, ip pim rp-address 22.22.22.22 group-list 227.0.0.0/8
#         vrf red, ip pim rp-address 23.23.23.23 group-list 228.0.0.0/8
#         vrf blue, ip pim rp-address 33.33.33.33 group-list 227.0.0.0/8
#         vrf blue, ip pim rp-address 34.34.34.34 group-list 228.0.0.0/8
#
# 3. test_same_rpaddr_same_grouplist_multiple_vrfs:
#         vrf default, ip pim rp-address 1.1.1.1 group-list 224.0.0.0/8
#         vrf default, ip pim rp-address 2.2.2.2 group-list 226.0.0.0/8
#         vrf default, ip pim rp-address 22.22.22.22 group-list 226.0.0.0/8
#         vrf red, ip pim rp-address 1.1.1.1 group-list 224.0.0.0/8
#         vrf red, ip pim rp-address 2.2.2.2 group-list 226.0.0.0/8
#         vrf red, ip pim rp-address 22.22.22.22 group-list 226.0.0.0/8
#         vrf black, ip pim rp-address 1.1.1.1 group-list 224.0.0.0/8
#         vrf black, ip pim rp-address 2.2.2.2 group-list 226.0.0.0/8
#         vrf black, ip pim rp-address 22.22.22.22 group-list 226.0.0.0/8
#
# 4. test_single_invalid_rpaddr_single_grouplist_single_vrf:
#         vrf default, ip pim rp-address 256.256.256.256 group-list 224.0.0.0/8
#
# 5. test_single_rpaddr_single_invalid_grouplist_single_vrf:
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
    config('feature pim')
  end

  # Creates single group list under vrf default
  #--------------------------------------------
  def create_single_grouplist_single_vrf(afi)
    rp_addr_d1 = '11.11.11.11'
    rp_addr_d2 = '22.22.22.22'
    rp_addr_d3 = '23.23.23.23'
    vrf = 'default'
    grouplist1 = '227.0.0.0/8'
    grouplist2 = '228.0.0.0/8'
    pd1 = PimGroupList.new(afi, rp_addr_d1, grouplist1)
    pd2 = PimGroupList.new(afi, rp_addr_d2, grouplist2)
    pd3 = PimGroupList.new(afi, rp_addr_d3, grouplist2)

    result = PimGroupList.group_lists

    rp_addr_d1_def_grouplist1 = [rp_addr_d1, grouplist1]
    rp_addr_d2_def_grouplist2 = [rp_addr_d2, grouplist2]
    rp_addr_d3_def_grouplist2 = [rp_addr_d3, grouplist2]

    assert_includes(result[afi][rp_addr_d1_def_grouplist1], vrf)
    assert_includes(result[afi][rp_addr_d2_def_grouplist2], vrf)
    assert_includes(result[afi][rp_addr_d3_def_grouplist2], vrf)

    pd1.destroy
    pd2.destroy
    pd3.destroy
  end

  # Tests single group list under vrf default
  #------------------------------------------
  def test_single_grouplist_single_vrf
    %w(ipv4).each do |afi|
      create_single_grouplist_single_vrf(afi)
    end
  end

  # Creates multiple rp addresses under different vrfs
  #--------------------------------------------------
  def create_multiple_rpaddrs_multiple_vrfs(afi)
    rp_addr1 = '11.11.11.11'
    rp_addr12 = '12.12.12.12'
    vrf1 = 'default'
    rp_addr2 = '22.22.22.22'
    rp_addr23 = '23.23.23.23'
    vrf2 = 'red'
    rp_addr3 = '33.33.33.33'
    rp_addr34 = '34.34.34.34'
    vrf3 = 'blue'
    grouplist1 = '227.0.0.0/8'
    grouplist2 = '228.0.0.0/8'
    p1 = PimGroupList.new(afi, rp_addr1, grouplist1)
    p12 = PimGroupList.new(afi, rp_addr12, grouplist2)
    p2 = PimGroupList.new(afi, rp_addr2, grouplist1, vrf2)
    p23 = PimGroupList.new(afi, rp_addr23, grouplist2, vrf2)
    p3 = PimGroupList.new(afi, rp_addr3, grouplist1, vrf3)
    p34 = PimGroupList.new(afi, rp_addr34, grouplist2, vrf3)

    result = PimGroupList.group_lists

    rp_addr1_def_grouplist1 = [rp_addr1, grouplist1]
    rp_addr12_def_grouplist2 = [rp_addr12, grouplist2]
    rp_addr2_def_grouplist1 = [rp_addr2, grouplist1]
    rp_addr23_def_grouplist2 = [rp_addr23, grouplist2]
    rp_addr3_def_grouplist1 = [rp_addr3, grouplist1]
    rp_addr34_def_grouplist2 = [rp_addr34, grouplist2]

    assert_includes(result[afi][rp_addr1_def_grouplist1], vrf1)
    assert_includes(result[afi][rp_addr12_def_grouplist2], vrf1)
    assert_includes(result[afi][rp_addr2_def_grouplist1], vrf2)
    assert_includes(result[afi][rp_addr23_def_grouplist2], vrf2)
    assert_includes(result[afi][rp_addr3_def_grouplist1], vrf3)
    assert_includes(result[afi][rp_addr34_def_grouplist2], vrf3)
    p1.destroy
    p12.destroy
    p2.destroy
    p23.destroy
    p3.destroy
    p34.destroy
  end

  # Tests multiple rp addresses under different vrfs
  #--------------------------------------------------
  def test_multiple_rpaddrs_multiple_vrfs
    %w(ipv4).each do |afi|
      create_multiple_rpaddrs_multiple_vrfs(afi)
    end
  end

  # Creates same rp address and same grouplists under multiple vrfs
  #--------------------------------------------------------------
  def create_same_rpaddr_same_grouplist_multiple_vrfs(afi)
    rp_addr_d1 = '1.1.1.1'
    rp_addr_d2 = '2.2.2.2'
    rp_addr_d3 = '22.22.22.22'
    vrf = 'default'
    vrf2 = 'red'
    vrf3 = 'black'
    grouplist1 = '224.0.0.0/8'
    grouplist2 = '226.0.0.0/8'
    pd1 = PimGroupList.new(afi, rp_addr_d1, grouplist1)
    pd2 = PimGroupList.new(afi, rp_addr_d2, grouplist2)
    pd3 = PimGroupList.new(afi, rp_addr_d3, grouplist2)

    p1_red = PimGroupList.new(afi, rp_addr_d1, grouplist1, vrf2)
    p2_red = PimGroupList.new(afi, rp_addr_d2, grouplist2, vrf2)
    p3_red = PimGroupList.new(afi, rp_addr_d3, grouplist2, vrf2)

    p1_black = PimGroupList.new(afi, rp_addr_d1, grouplist1, vrf3)
    p2_black = PimGroupList.new(afi, rp_addr_d2, grouplist2, vrf3)
    p3_black = PimGroupList.new(afi, rp_addr_d3, grouplist2, vrf3)

    result = PimGroupList.group_lists

    rp_addr_d1_def_grouplist1 = [rp_addr_d1, grouplist1]
    rp_addr_d2_def_grouplist2 = [rp_addr_d2, grouplist2]
    rp_addr_d3_def_grouplist2 = [rp_addr_d3, grouplist2]

    assert_includes(result[afi][rp_addr_d1_def_grouplist1], vrf)
    assert_includes(result[afi][rp_addr_d2_def_grouplist2], vrf)
    assert_includes(result[afi][rp_addr_d3_def_grouplist2], vrf)

    assert_includes(result[afi][rp_addr_d1_def_grouplist1], vrf2)
    assert_includes(result[afi][rp_addr_d2_def_grouplist2], vrf2)
    assert_includes(result[afi][rp_addr_d3_def_grouplist2], vrf2)

    assert_includes(result[afi][rp_addr_d1_def_grouplist1], vrf3)
    assert_includes(result[afi][rp_addr_d2_def_grouplist2], vrf3)
    assert_includes(result[afi][rp_addr_d3_def_grouplist2], vrf3)

    pd1.destroy
    pd2.destroy
    pd3.destroy

    p1_red.destroy
    p2_red.destroy
    p3_red.destroy

    p1_black.destroy
    p2_black.destroy
    p3_black.destroy
  end

  # Tests same rp address and same grouplists under multiple vrfs
  #--------------------------------------------------------------
  def test_same_rpaddr_same_grouplist_multiple_vrfs
    %w(ipv4).each do |afi|
      create_same_rpaddr_same_grouplist_multiple_vrfs(afi)
    end
  end

  # Creates single invalid rp address single grouplist vrf default
  #---------------------------------------------------------------
  def create_single_invalid_rpaddr_single_grouplist_single_vrf(afi)
    rp_addr = '256.256.256.256'
    grouplist = '224.0.0.0/8'
    assert_raises(CliError) do
      PimGroupList.new(afi, rp_addr, grouplist)
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
    vrf = 'red'
    assert_raises(CliError) do
      PimGroupList.new(afi, rp_addr, grouplist, vrf)
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
