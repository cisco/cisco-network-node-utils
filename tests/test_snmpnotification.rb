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

# TestSnmpNotification - Minitest for SnmpNotification node utility.
class TestSnmpNotification < CiscoTestCase
  @skip_unless_supported = 'snmpnotification'
  def setup
    # setup runs at the beginning of each test
    super
    no_snmp_notification
    if platform == :nexus
      config('no feature bgp')
      config('feature bgp')
    else
      config('snmp-server traps bgp')
    end
  end

  def teardown
    # teardown runs at the end of each test
    no_snmp_notification
    config('no feature bgp') if platform == :nexus
    super
  end

  def no_snmp_notification
    # Turn the feature off for a clean test.
    if platform == :nexus
      config('no snmp-server enable traps')
    else
      config('no snmp-server traps')
    end
  end

  # TESTS

  def test_snmp_notification
    # test traps returned
    assert_equal(false, Cisco::SnmpNotification.notifications.empty?,
                 'notifications is not empty')
    if platform == :nexus
      assert_equal(Cisco::SnmpNotification,
                   Cisco::SnmpNotification.notifications['vtp notifs'].class,
                   'vtp notifs exists')
    else
      assert_equal(Cisco::SnmpNotification,
                   Cisco::SnmpNotification.notifications['bgp'].class,
                   'bgp exists')
    end

    # set up some traps
    if platform == :nexus
      trap1 = Cisco::SnmpNotification.new('cfs state-change-notif')
      trap2 = Cisco::SnmpNotification.new('bgp cbgp2 state-changes')
    else
      trap1 = Cisco::SnmpNotification.new('bfd')
      trap2 = Cisco::SnmpNotification.new('flash insertion')
    end
    # Default Checking
    assert_equal(trap1.enable, false)
    assert_equal(trap2.enable, false)

    trap1.enable = true
    trap2.enable = true
    assert_equal(trap1.enable, true)
    assert_equal(trap2.enable, true)

    # Setting back to default and re-checking
    trap1.enable = false
    trap2.enable = false
    assert_equal(trap1.enable, false)
    assert_equal(trap2.enable, false)
  end
end
