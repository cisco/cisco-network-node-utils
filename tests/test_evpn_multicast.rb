# Evpn Multicast Unit Tests
#
# Rahul Shenoy, January, 2018
#
# Copyright (c) 2018 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/evpn_multicast'
require_relative '../lib/cisco_node_utils/feature'

# TestEvpnMulticast - Minitest for EvpnMulticast class
class TestEvpnMulticast < CiscoTestCase
  @skip_unless_supported = 'evpn_multicast'

  def setup
    # Disable feature ngmvpn before each test to
    # ensure we are starting with a clean slate for each test.
    super
    config('no feature ngmvpn')
    config('no advertise evpn multicast')
  end

  def teardown
    # disable feature ngmvpn and advertise evpn multicast
    # after each test
    config('no feature ngmvpn')
    config('no advertise evpn multicast')
    super
  end

  def test_create_and_destroy
    mc = EvpnMulticast.new
    assert_equal('advertise evpn multicast', mc.multicast,
                 'Error: failed to enable evpn multicast')
    assert(Feature.ngmvpn_enabled?,
           'Error: failed to enable feature ngmvpn')
    mc.destroy
    assert_equal('', mc.multicast,
                 'Error: failed to disable evpn multicast')
  end

  def test_multicast
    mc = EvpnMulticast.new
    mc.multicast = false
    assert_equal('', mc.multicast,
                 'Error: failed to disable evpn multicast')
    mc.multicast = true
    assert_equal('advertise evpn multicast', mc.multicast,
                 'Error: failed to enable evpn multicast')
    mc.destroy
  end
end
