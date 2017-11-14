# Evpn Stormcontrol Unit Tests
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
require_relative '../lib/cisco_node_utils/evpn_stormcontrol'

# TestEvpnStormcontrol - Minitest for EvpnStormcontrol class
class TestEvpnStormcontrol < CiscoTestCase
  @skip_unless_supported = 'evpn_stormcontrol'

  def setup
    # Ensure we are starting with a clean slate for each test.
    super
    skip("#{node.product_id} doesn't support this feature") unless
      node.product_id[/N9K.*EX/]
    config('no evpn storm-control broadcast level 50')
    config('no evpn storm-control multicast level 50')
    config('no evpn storm-control unicast level 50')
  end

  def test_create_and_destroy
    sc = EvpnStormcontrol.new('broadcast', 50)
    sc_level = EvpnStormcontrol.broadcast
    assert_equal('50', sc_level,
                 'Error: failed to configure evpn storm-control broadcast ' \
                 'level 50')
    sc.destroy
    sc_level = EvpnStormcontrol.broadcast
    assert_nil(sc_level, 'Error: failed to destroy storm-control config')
  end

  def test_update_level
    sc = EvpnStormcontrol.new('multicast', 50)
    assert_equal('50', EvpnStormcontrol.multicast,
                 'Error: multicast storm-control level should be 50')
    sc.level = 51
    assert_equal('51', EvpnStormcontrol.multicast,
                 'Error: failed to create multisite border-gateway 200')
    sc.destroy
  end
end
