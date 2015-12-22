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
# ---------------------------------------------------------------------
# Cli: <afi> pim rp-address <rp-address> (under different VRFs)
# ---------------------------------------------------------------------
# Testcases: All Tests create and destroy all instances within a test
#
# 1. test_single_rpaddr_single_vrf :
#         vrf default, ip pim rp-address 1.1.1.1
#
# 2. test_multiple_rpaddrs_multiple_vrfs:
#         vrf default, ip pim rp-address 11.11.11.11
#         vrf default, ip pim rp-address 12.12.12.12
#         vrf red, ip pim rp-address 22.22.22.22
#         vrf red, ip pim rp-address 23.23.23.23
#         vrf blue, ip pim rp-address 33.33.33.33
#         vrf blue, ip pim rp-address 34.34.34.34
#
# 3. test_same_rpaddr_multiple_vrfs:
#         vrf default, ip pim rp-address 66.66.66.66
#         vrf red, ip pim rp-address 66.66.66.66
#         vrf blue, ip pim rp-address 66.66.66.66
#
# 4. test_single_invalid_rpaddr_single_vrf:
#         vrf default, ip pim rp-address 256.256.256.256
# ---------------------------------------------------------------------

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/pim_rp_address'

include Cisco

# TestPimRpAddress - Minitest for PimRpAddress
class TestPimRpAddress < CiscoTestCase
  # Enables feature pim
  #--------------------
  def setup
    super
    config('no feature pim')
    config('feature pim')
  end

  # Creates single rp address under vrf default
  #------------------------------------------
  def create_single_rpaddr_single_vrf(afi)
    rp_addr = '1.1.1.1'
    vrf = 'default'
    p1 = PimRpAddress.new(afi, rp_addr)
    result = PimRpAddress.rp_addresses
    assert_includes(result[afi][rp_addr], vrf)
    p1.destroy
  end

  # Tests single rp address under vrf default
  #------------------------------------------
  def test_single_rpaddr_single_vrf
    %w(ipv4).each do |afi|
      create_single_rpaddr_single_vrf(afi)
    end
  end

  # Creates multiple rp addresses under different vrfs
  #--------------------------------------------------
  def create_multiple_rpaddrs_multiple_vrfs(afi)
    rp_addr11 = '11.11.11.11'
    rp_addr12 = '12.12.12.12'
    vrf1 = 'default'
    rp_addr22 = '22.22.22.22'
    rp_addr23 = '23.23.23.23'
    vrf2 = 'red'
    rp_addr33 = '33.33.33.33'
    rp_addr34 = '34.34.34.34'
    vrf3 = 'blue'
    p11 = PimRpAddress.new(afi, rp_addr11)
    p12 = PimRpAddress.new(afi, rp_addr12)
    p22 = PimRpAddress.new(afi, rp_addr22, vrf2)
    p23 = PimRpAddress.new(afi, rp_addr23, vrf2)
    p33 = PimRpAddress.new(afi, rp_addr33, vrf3)
    p34 = PimRpAddress.new(afi, rp_addr34, vrf3)

    result = PimRpAddress.rp_addresses
    assert_includes(result[afi][rp_addr11], vrf1)
    assert_includes(result[afi][rp_addr12], vrf1)
    assert_includes(result[afi][rp_addr22], vrf2)
    assert_includes(result[afi][rp_addr23], vrf2)
    assert_includes(result[afi][rp_addr33], vrf3)
    assert_includes(result[afi][rp_addr34], vrf3)
    p11.destroy
    p12.destroy
    p22.destroy
    p23.destroy
    p33.destroy
    p34.destroy
  end

  # Tests multiple rp addresses under different vrfs
  #------------------------------------------
  def test_multiple_rpaddrs_multiple_vrfs
    %w(ipv4).each do |afi|
      create_multiple_rpaddrs_multiple_vrfs(afi)
    end
  end

  # Creates same rp address under multiple vrfs
  #-------------------------------------------
  def create_same_rpaddr_multiple_vrfs(afi)
    rp_addr = '66.66.66.66'
    vrf1 = 'default'
    vrf2 = 'red'
    vrf3 = 'blue'
    p1 = PimRpAddress.new(afi, rp_addr)
    p2 = PimRpAddress.new(afi, rp_addr, vrf2)
    p3 = PimRpAddress.new(afi, rp_addr, vrf3)

    result = PimRpAddress.rp_addresses
    assert_includes(result[afi][rp_addr], vrf1)
    assert_includes(result[afi][rp_addr], vrf2)
    assert_includes(result[afi][rp_addr], vrf3)
    p1.destroy
    p2.destroy
    p3.destroy
  end

  # Tests same rp address under multiple vrfs
  #-------------------------------------------
  def test_same_rpaddr_multiple_vrfs
    %w(ipv4).each do |afi|
      create_same_rpaddr_multiple_vrfs(afi)
    end
  end

  # Creates single invalid rp address under vrf default
  #---------------------------------------------------
  def create_single_invalid_rpaddr_single_vrf(afi)
    rp_addr = '256.256.256.256'
    assert_raises(CliError) do
      PimRpAddress.new(afi, rp_addr)
    end
  end

  # Tests single invalid rp address under vrf default
  #---------------------------------------------------
  def test_single_invalid_rpaddr_single_vrf
    %w(ipv4).each do |afi|
      create_single_invalid_rpaddr_single_vrf(afi)
    end
  end
end
