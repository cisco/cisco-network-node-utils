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
    config('no feature ngmvpn')
  end

  def teardown
    # Disable feature ngmvpn after each test
    config('no feature ngmvpn')
    super
  end

  def test_ip_multicast
    ipm = IpMulticast.new
    opts = %w(overlay_distributed_dr overlay_spt_only)

    # test defaults
    opts.each do |opt|
      have = ipm.send("#{opt}")
      should = ipm.send("default_#{opt}")
      assert_equal(have, should, "#{opt} doesn't match the default")
    end

    # test property set
    opts.each do |opt|
      ipm.send("#{opt}=", true)
      should = 'ip multicast ' + opt.tr('_', '-')
      assert_equal(ipm.send("#{opt}"), should, "#{opt} was not set")
    end

    # unset property
    opts.each do |opt|
      ipm.send("#{opt}=", false)
      should = ''
      assert_equal(ipm.send("#{opt}"), should, "#{opt} was not unset")
      assert_equal(ipm.send("#{opt}"), ipm.send("default_#{opt}"), "#{opt} doesn't match default")
    end

    ipm.destroy
  end
end
