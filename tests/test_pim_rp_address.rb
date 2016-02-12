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
# ---------------------------------------------------------------------
# Cli: <afi> pim rp-address <rp-address> (under different VRFs)
# ---------------------------------------------------------------------
# Testcases: All Tests create and destroy all instances within a test
#
# 1. test_all_rp_addrs
#
# 2. test_single_invalid_rpaddr_single_vrf:
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
  end

  # Test PimRpAddress.rp_addresses
  # - multiple vrfs, rp_addrs
  # - same rp_addr, different vrf
  #--------------------------------------------
  def all_rp_addrs(afi)
    rp_addr1 = '11.11.11.11'
    rp_addr2 = '22.22.22.22'

    # Basic setup
    vrf = 'default'
    pd1 = PimRpAddress.new(afi, vrf, rp_addr1)
    pd2 = PimRpAddress.new(afi, vrf, rp_addr2)
    hash = PimRpAddress.rp_addresses
    assert(hash.key?(afi))
    assert(hash[afi].key?(vrf))
    assert_equal(2, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 2 rp-address")
    assert(hash[afi][vrf].key?(rp_addr1),
           "hash[#{afi}][#{vrf}] does not contain #{rp_addr1}")
    assert(hash[afi][vrf].key?(rp_addr2),
           "hash[#{afi}][#{vrf}] does not contain #{rp_addr2}")

    # vrf with same rp_addrs as in default
    vrf = 'red'
    pd3 = PimRpAddress.new(afi, vrf, rp_addr1)
    pd4 = PimRpAddress.new(afi, vrf, rp_addr2)
    hash = PimRpAddress.rp_addresses
    assert_equal(2, hash[afi].keys.count,
                 "hash[#{afi}] does not have 2 vrfs")
    assert(hash[afi].key?(vrf))
    assert_equal(2, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 2 rp-address")
    assert(hash[afi][vrf].key?(rp_addr1),
           "hash[#{afi}][#{vrf}] does not contain #{rp_addr1}")
    assert(hash[afi][vrf].key?(rp_addr2),
           "hash[#{afi}][#{vrf}] does not contain #{rp_addr2}")

    # different vrf, same/diff rps
    vrf = 'black'
    rp_addr7 = '7.7.7.7'
    pd5 = PimRpAddress.new(afi, vrf, rp_addr1)
    pd6 = PimRpAddress.new(afi, vrf, rp_addr2)
    pd7 = PimRpAddress.new(afi, vrf, rp_addr7)
    hash = PimRpAddress.rp_addresses
    assert_equal(3, hash[afi].keys.count,
                 "hash[#{afi}] does not have 3 vrfs")
    assert(hash[afi].key?(vrf))
    assert_equal(3, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 3 rp-address")
    assert(hash[afi][vrf].key?(rp_addr1),
           "hash[#{afi}][#{vrf}] does not contain #{rp_addr1}")
    assert(hash[afi][vrf].key?(rp_addr1),
           "hash[#{afi}][#{vrf}] does not contain #{rp_addr2}")
    assert(hash[afi][vrf].key?(rp_addr7),
           "hash[#{afi}][#{vrf}] does not contain #{rp_addr7}")

    # Test removal
    vrf = 'default'
    pd1.destroy
    hash = PimRpAddress.rp_addresses
    assert_equal(1, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 1 rp-address")
    refute(hash[afi][vrf].key?(rp_addr1),
           "hash[#{afi}][#{vrf}] should not contain #{rp_addr1}")

    vrf = 'red'
    pd3.destroy
    hash = PimRpAddress.rp_addresses
    assert_equal(1, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 1 rp-address")
    refute(hash[afi][vrf].key?(rp_addr1),
           "hash[#{afi}][#{vrf}] should not contain #{rp_addr1}")

    vrf = 'black'
    pd5.destroy
    pd7.destroy
    hash = PimRpAddress.rp_addresses
    assert_equal(1, hash[afi][vrf].keys.count,
                 "hash[#{afi}][#{vrf}] should have 1 rp-address")
    refute(hash[afi][vrf].key?([rp_addr1]),
           "hash[#{afi}][#{vrf}] should not contain [#{rp_addr1}]")
    pd2.destroy
    pd4.destroy
    pd6.destroy
    hash = PimRpAddress.rp_addresses
    assert_empty(hash[afi], 'hash[#{afi}] is not empty')
  end

  # Tests PimRpAddress.rp_addresses
  #------------------------------------------
  def test_all_rp_addrs
    %w(ipv4).each do |afi|
      all_rp_addrs(afi)
    end
  end

  # Creates single invalid rp address under vrf default
  #---------------------------------------------------
  def create_single_invalid_rpaddr_single_vrf(afi)
    rp_addr = '256.256.256.256'
    assert_raises(CliError) do
      PimRpAddress.new(afi, 'default', rp_addr)
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
