# Evpn Multisite Unit Tests
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
require_relative '../lib/cisco_node_utils/evpn_multisite'

# TestEvpnMultisite - Minitest for EvpnMultisite class
class TestEvpnMultisite < CiscoTestCase
  @skip_unless_supported = 'evpn_multisite'

  def setup
    # Disable feature nv overlay before each test to
    # ensure we are starting with a clean slate for each test.
    super
    skip("#{node.product_id} doesn't support this feature") unless
      node.product_id[/N9K.*EX/]
    config('no feature nv overlay')
  end

  def test_create_and_destroy
    ms = EvpnMultisite.new(100)
    ms_id = ms.multisite
    assert_equal('100', ms_id,
                 'Error: failed to create multisite border-gateway 100')
    ms.destroy
    ms_id = ms.multisite
    assert_nil(ms_id, 'Error: failed to destroy multisite border-gateway 100')
  end

  def test_delay_restore
    ms = EvpnMultisite.new(100)
    ms.delay_restore = 31
    assert_equal('31', ms.delay_restore,
                 'multisite border-gateway delay_restore should be 31')
    ms.delay_restore = 1000
    assert_equal('1000', ms.delay_restore,
                 'multisite border-gateway delay_restore should be 1000')
    ms.destroy
  end

  def test_update_multisiteid
    ms = EvpnMultisite.new(100)
    ms.delay_restore = 50
    assert_equal('100', ms.multisite,
                 'Error: failed to create multisite border-gateway 100')
    assert_equal('50', ms.delay_restore,
                 'multisite border-gateway delay_restore should be 50')
    ms.multisite = 200
    assert_equal('200', ms.multisite,
                 'Error: failed to create multisite border-gateway 200')
    assert_equal('50', ms.delay_restore,
                 'multisite border-gateway delay_restore should be 50')
    ms.destroy
  end
end
