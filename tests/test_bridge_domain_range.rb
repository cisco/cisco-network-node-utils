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
require_relative '../lib/cisco_node_utils/bridge_domain_range'

include Cisco

# TestBridgeDomainRange - Minitest for bridge domain class.
class TestBridgeDomainRange < CiscoTestCase
  @skip_unless_supported = 'bridge_domain_range'
  @@cleaned = false # rubocop:disable Style/ClassVars

  def cleanup
    BridgeDomainRange.rangebds.each do |_bd, obj|
      obj.destroy
    end
  end

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup unless @@cleaned
    super
    cleanup
  end

  def test_single_bd_member_vni
    mt_full_interface?
    bd = BridgeDomainRange.new('100')
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
    mt_full_interface?
    bd = BridgeDomainRange.new('100-110,150,170-171')
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

  def test_overwrite_bd_member_vni
    mt_full_interface?
    bd = BridgeDomainRange.new('100-110')
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

  def test_member_vni_empty_assign
    mt_full_interface?
    bd = BridgeDomainRange.new(100)
    bd.member_vni = ''
    assert_equal(bd.default_member_vni, bd.member_vni,
                 'Error: Bridge-Domain is mapped to different vnis')
    bd.destroy
  end
end
