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
require_relative '../lib/cisco_node_utils/bridge_domain_vni'

include Cisco

# TestBridgeDomainVNI - Minitest for bridge domain class.
class TestBridgeDomainVNI < CiscoTestCase
  @skip_unless_supported = 'bridge_domain_vni'
  @@cleaned = false # rubocop:disable Style/ClassVars

  def cleanup
    remove_all_vlans
    config_no_warn('no feature vni')
    BridgeDomainVNI.range_bds.each do |_bd, obj|
      obj.destroy
    end
  end

  def setup
    super
    vdc_limit_f3_no_intf_needed(:set)
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
    vdc_limit_f3_no_intf_needed(:clear) if first_or_last_teardown
    super
  end

  def test_single_bd_member_vni
    bd = BridgeDomainVNI.new('100')
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = '6000'
    bd.member_vni = vni
    assert_equal(vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.member_vni = ''
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.destroy
  end

  def test_multiple_bd_member_vni
    bd = BridgeDomainVNI.new('100-110, 150, 170-171 ')
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = '6000-6010,6050,5070-5071'
    bd.member_vni = vni
    assert_equal(vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.member_vni = ''
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.destroy
  end

  def test_member_vni_empty_assign
    bd = BridgeDomainVNI.new(100)
    bd.member_vni = ''
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')
    bd.destroy
  end

  def test_overwrite_bd_member_vni
    bd = BridgeDomainVNI.new('100-110')
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = '5000-5010'
    bd.member_vni = vni
    assert_equal(vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    vni = '5000-5005,6006-6010'
    bd.member_vni = vni
    assert_equal(vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.member_vni = ''
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')

    bd.destroy
  end
end
