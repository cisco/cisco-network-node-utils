# IP Multicast Unit Tests
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
require_relative '../lib/cisco_node_utils/ip_multicast'
require_relative '../lib/cisco_node_utils/feature'

# TestIpMulticast - Minitest for IpMulticast class
class TestIpMulticast < CiscoTestCase
  @skip_unless_supported = 'ip_multicast'

  def setup
    # Disable feature ngmvpn before each test to
    # ensure we are starting with a clean slate for each test.
    super
    skip_incompat_version?('feature', 'ngmvpn')
    config_no_warn('no feature ngmvpn')
  end

  def teardown
    # Disable feature ngmvpn after each test
    config_no_warn('no feature ngmvpn')
    super
  end

  def test_overlay_distributed_dr
    ipm = IpMulticast.new

    # Test Defaults
    have = ipm.overlay_distributed_dr
    should = ipm.default_overlay_distributed_dr
    assert_equal(have, should, "overlay_distributed_dr does not match default value")

    # Test property set
    ipm.overlay_distributed_dr = true
    assert_equal(ipm.overlay_distributed_dr, true, "overlay_distributed_dr was not set")

    # Test property unset
    ipm.overlay_distributed_dr = false
    assert_equal(ipm.overlay_distributed_dr, false, "overlay_distributed_dr was not unset")

    ipm.destroy
  end

  def test_overlay_spt_only
    ipm = IpMulticast.new

    # Test Defaults
    have = ipm.overlay_spt_only
    should = ipm.default_overlay_spt_only
    assert_equal(have, should, "overlay_spt_only does not match default value")

    # Test property set
    ipm.overlay_spt_only = true
    assert_equal(ipm.overlay_spt_only, true, "overlay_spt_only was not set")

    # Test property unset
    ipm.overlay_spt_only = false
    assert_equal(ipm.overlay_spt_only, false, "overlay_spt_only was not unset")

    ipm.destroy
  end
end
