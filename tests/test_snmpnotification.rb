#
# Minitest for snmpnotification class
#
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
require_relative '../lib/cisco_node_utils/snmpnotification'

# TestRadiusGlobal - Minitest for RadiusGlobal node utility.
class TestSnmpNotification < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_snmp_notification
    config('no feature bgp')
    config('feature bgp')
  end

  def teardown
    # teardown runs at the end of each test
    no_snmp_notification
    config('no feature bgp')
    super
  end

  def no_snmp_notification
    # Turn the feature off for a clean test.
    config('no snmp-server enable traps')
  end

  # TESTS

  def test_snmp_notification
    # test traps returned
    assert_equal(false, Cisco::SnmpNotification.notifications.empty?,
                 'notifications is not empty')
    assert_equal(Cisco::SnmpNotification,
                 Cisco::SnmpNotification.notifications['vtp notifs'].class,
                 'vtp notifs exists')

    # set up some traps
    cfs_state = Cisco::SnmpNotification.new('cfs state-change-notif')
    bgp = Cisco::SnmpNotification.new('bgp cbgp2 state-changes')

    # Default Checking
    assert_equal(cfs_state.enable, false)
    assert_equal(bgp.enable, false)

    cfs_state.enable = true
    bgp.enable = true
    assert_equal(cfs_state.enable, true)
    assert_equal(bgp.enable, true)

    # Setting back to default and re-checking
    cfs_state.enable = false
    bgp.enable = false
    assert_equal(cfs_state.enable, false)
    assert_equal(bgp.enable, false)
  end
end
