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
require_relative '../lib/cisco_node_utils/interface_hsrp'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestInterfaceHsrp < CiscoTestCase
  @skip_unless_supported = 'interface_hsrp'
  # TESTS

  def setup
    super
    config_no_warn('no feature hsrp')
  end

  def teardown
    config_no_warn('no feature hsrp') if first_or_last_teardown
    super
  end

  def create_intf_hsrp
    interface = Interface.new(interfaces[0])
    interface.switchport_mode = :disabled
    InterfaceHsrp.new(interfaces[0])
  end

  def test_bfd
    ih = create_intf_hsrp
    assert_equal(ih.default_bfd, ih.bfd)
    ih.bfd = true
    assert_equal(true, ih.bfd)
    ih.bfd = ih.default_bfd
    assert_equal(ih.default_bfd, ih.bfd)
  end

  def test_delay
    ih = create_intf_hsrp
    assert_equal(ih.default_delay_minimum, ih.delay_minimum)
    assert_equal(ih.default_delay_reload, ih.delay_reload)
    ih.delay_minimum = 100
    ih.delay_reload = 555
    assert_equal(100, ih.delay_minimum)
    assert_equal(555, ih.delay_reload)
    ih.delay_minimum = ih.default_delay_minimum
    ih.delay_reload = ih.default_delay_reload
    assert_equal(ih.default_delay_minimum, ih.delay_minimum)
    assert_equal(ih.default_delay_reload, ih.delay_reload)
  end

  def test_mac_refresh
    ih = create_intf_hsrp
    assert_equal(ih.default_mac_refresh, ih.mac_refresh)
    ih.mac_refresh = 60
    assert_equal(60, ih.mac_refresh)
    ih.mac_refresh = ih.default_mac_refresh
    assert_equal(ih.default_mac_refresh, ih.mac_refresh)
  end

  def test_use_bia
    ih = create_intf_hsrp
    assert_equal(ih.default_use_bia, ih.use_bia)
    ih.use_bia = :use_bia
    assert_equal(:use_bia, ih.use_bia)
    ih.use_bia = :use_bia_intf
    assert_equal(:use_bia_intf, ih.use_bia)
    ih.use_bia = :use_bia
    assert_equal(:use_bia, ih.use_bia)
    ih.use_bia = ih.default_use_bia
    assert_equal(ih.default_use_bia, ih.use_bia)
  end

  def test_version
    ih = create_intf_hsrp
    assert_equal(ih.default_version, ih.version)
    ih.version = 2
    assert_equal(2, ih.version)
    ih.version = ih.default_version
    assert_equal(ih.default_version, ih.version)
  end
end
