# Interface Evpn Multisite Unit Tests
#
# Rahul Shenoy, October, 2017
#
# Copyright (c) 2017 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/interface_evpn_multisite'
require_relative '../lib/cisco_node_utils/evpn_multisite'

# TestInterfaceEvpnMultisite - Minitest for InterfaceEvpnMultisite class
class TestInterfaceEvpnMultisite < CiscoTestCase
  @skip_unless_supported = 'interface_evpn_multisite'

  def setup
    # ensure we are starting with a clean slate for each test.
    super
    skip("#{node.product_id} doesn't support this feature") unless
      node.product_id[/N9K.*EX/]
    interface_ethernet_default(interfaces[0])
  end

  def interface_ethernet_default(intf)
    config("default interface #{intf}")
  end

  def test_enable_disable
    interface = interfaces[0]
    intf_ms = InterfaceEvpnMultisite.new(interface)
    ms = EvpnMultisite.new(100)
    intf_ms.enable('dci-tracking')
    assert_equal('dci-tracking', intf_ms.tracking)
    intf_ms.disable('dci-tracking')
    assert_nil(intf_ms.tracking)
    ms.destroy
  end

  def test_enable_with_no_multisite_bordergateway
    interface = interfaces[0]
    intf_ms = InterfaceEvpnMultisite.new(interface)
    ms = EvpnMultisite.new(100)
    ms.destroy
    assert_raises(CliError, 'Invalid command') do
      intf_ms.enable('dci-tracking')
    end
  end
end
