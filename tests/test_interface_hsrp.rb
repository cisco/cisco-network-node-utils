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
require_relative '../lib/cisco_node_utils/interface'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestInterfaceHsrp < CiscoTestCase
  @skip_unless_supported = 'interface'
  # TESTS

  def setup
    super
    config_no_warn('no feature hsrp')
  end

  def teardown
    config_no_warn('no feature hsrp') if first_or_last_teardown
    super
  end

  def create_intf
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    interface
  end

  def test_hsrp_bfd
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ih = create_intf
    if validate_property_excluded?('interface', 'hsrp_bfd')
      assert_nil(ih.hsrp_bfd)
      assert_raises(Cisco::UnsupportedError) do
        ih.hsrp_bfd = true
      end
      return
    end
    assert_equal(ih.default_hsrp_bfd, ih.hsrp_bfd)
    ih.hsrp_bfd = true
    assert_equal(true, ih.hsrp_bfd)
    ih.hsrp_bfd = ih.default_hsrp_bfd
    assert_equal(ih.default_hsrp_bfd, ih.hsrp_bfd)
  end

  def test_hsrp_delay
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ih = create_intf
    if validate_property_excluded?('interface', 'hsrp_delay')
      assert_nil(ih.hsrp_delay_minimum)
      assert_nil(ih.hsrp_delay_reload)
      assert_raises(Cisco::UnsupportedError) do
        ih.hsrp_delay_minimum = 100
        ih.hsrp_delay_reload = 555
      end
      return
    end
    assert_equal(ih.default_hsrp_delay_minimum, ih.hsrp_delay_minimum)
    assert_equal(ih.default_hsrp_delay_reload, ih.hsrp_delay_reload)
    ih.hsrp_delay_minimum = 100
    ih.hsrp_delay_reload = 555
    assert_equal(100, ih.hsrp_delay_minimum)
    assert_equal(555, ih.hsrp_delay_reload)
    ih.hsrp_delay_minimum = ih.default_hsrp_delay_minimum
    ih.hsrp_delay_reload = ih.default_hsrp_delay_reload
    assert_equal(ih.default_hsrp_delay_minimum, ih.hsrp_delay_minimum)
    assert_equal(ih.default_hsrp_delay_reload, ih.hsrp_delay_reload)
  end

  def test_hsrp_mac_refresh
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ih = create_intf
    if validate_property_excluded?('interface', 'hsrp_mac_refresh')
      assert_nil(ih.hsrp_mac_refresh)
      assert_raises(Cisco::UnsupportedError) do
        ih.hsrp_mac_refresh = 60
      end
      return
    end
    assert_equal(ih.default_hsrp_mac_refresh, ih.hsrp_mac_refresh)
    ih.hsrp_mac_refresh = 60
    assert_equal(60, ih.hsrp_mac_refresh)
    ih.hsrp_mac_refresh = ih.default_hsrp_mac_refresh
    assert_equal(ih.default_hsrp_mac_refresh, ih.hsrp_mac_refresh)
  end

  def test_hsrp_use_bia
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ih = create_intf
    if validate_property_excluded?('interface', 'hsrp_use_bia')
      assert_nil(ih.hsrp_use_bia)
      assert_raises(Cisco::UnsupportedError) do
        ih.hsrp_use_bia = :use_bia
      end
      return
    end
    assert_equal(ih.default_hsrp_use_bia, ih.hsrp_use_bia)
    ih.hsrp_use_bia = :use_bia
    assert_equal(:use_bia, ih.hsrp_use_bia)
    ih.hsrp_use_bia = :use_bia_intf
    assert_equal(:use_bia_intf, ih.hsrp_use_bia)
    ih.hsrp_use_bia = :use_bia
    assert_equal(:use_bia, ih.hsrp_use_bia)
    ih.hsrp_use_bia = ih.default_hsrp_use_bia
    assert_equal(ih.default_hsrp_use_bia, ih.hsrp_use_bia)
  end

  def test_hsrp_version
    skip_legacy_defect?('7.3.0.D1.1', 'CSCuh90262: hsrp indentation')
    ih = create_intf
    if validate_property_excluded?('interface', 'hsrp_version')
      assert_nil(ih.hsrp_version)
      assert_raises(Cisco::UnsupportedError) do
        ih.hsrp_version = 2
      end
      return
    end
    assert_equal(ih.default_hsrp_version, ih.hsrp_version)
    ih.hsrp_version = 2
    assert_equal(2, ih.hsrp_version)
    ih.hsrp_version = ih.default_hsrp_version
    assert_equal(ih.default_hsrp_version, ih.hsrp_version)
  end
end
