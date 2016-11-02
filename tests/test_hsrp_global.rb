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
require_relative '../lib/cisco_node_utils/hsrp_global'

include Cisco
# TestHsrpGlobal - Minitest for general functionality
# of the HsrpGlobal class.
class TestHsrpGlobal < CiscoTestCase
  @skip_unless_supported = 'hsrp_global'

  # Tests
  def setup
    super
    config_no_warn('no feature hsrp')
  end

  def teardown
    config_no_warn('no feature hsrp') if first_or_last_teardown
    super
  end

  def test_collection_empty
    hg = HsrpGlobal.globals
    assert_empty(hg)
  end

  def test_destroy
    hg = HsrpGlobal.new
    assert_equal(true, Feature.hsrp_enabled?)

    hg.destroy
    [:bfd_all_intf,
     :extended_hold,
    ].each do |prop|
      assert_equal(hg.send("default_#{prop}"), hg.send("#{prop}")) if
        hg.send("#{prop}")
    end
  end

  def test_bfd_all_intf
    hg = HsrpGlobal.new
    if validate_property_excluded?('hsrp_global', 'bfd_all_intf')
      assert_nil(hg.bfd_all_intf)
      assert_raises(Cisco::UnsupportedError) do
        hg.bfd_all_intf = true
      end
      return
    end
    assert_equal(hg.default_bfd_all_intf, hg.bfd_all_intf)
    hg.bfd_all_intf = true
    assert_equal(true, hg.bfd_all_intf)
    hg.bfd_all_intf = hg.default_bfd_all_intf
    assert_equal(hg.default_bfd_all_intf, hg.bfd_all_intf)
  end

  def test_extended_hold
    hg = HsrpGlobal.new
    assert_equal(hg.default_extended_hold, hg.extended_hold)
    hg.extended_hold = '100'
    assert_equal('100', hg.extended_hold)
    hg.extended_hold = '10'
    assert_equal('10', hg.extended_hold)
    hg.extended_hold = hg.default_extended_hold
    assert_equal(hg.default_extended_hold, hg.extended_hold)
  end
end
