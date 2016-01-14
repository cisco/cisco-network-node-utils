#
# Minitest for SnmpNotificationReceiver class
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/snmp_notification_receiver'

# TestSnmpNotificationReceiver - Minitest for SnmpNotificationReceiver
# node utility.
class TestSnmpNotificationReceiver < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_snmpnotificationreceiver
    config('vrf context red')
  end

  def teardown
    # teardown runs at the end of each test
    no_snmpnotificationreceiver
    config('no vrf context red')
    super
  end

  def no_snmpnotificationreceiver
    # Turn the feature off for a clean test.
    config('no snmp-server host 4.5.6.7 informs version 3 priv ab udp-port 45',
           'no snmp-server host 8.9.10.11 traps version 3 auth cd udp-port 46')
  end

  # TESTS

  def test_create_destroy_single
    id = '4.5.6.7'
    refute_includes(Cisco::SnmpNotificationReceiver.receivers, id)

    receiver = \
      Cisco::SnmpNotificationReceiver.new(id,
                                          instantiate:      true,
                                          type:             'informs',
                                          version:          '3',
                                          security:         'priv',
                                          username:         'ab',
                                          port:             '45',
                                          vrf:              'red',
                                          source_interface: 'ethernet1/3')

    assert_includes(Cisco::SnmpNotificationReceiver.receivers, id)
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id], receiver)

    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].source_interface,
                 'ethernet1/3')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].port, '45')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].type, 'informs')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].username, 'ab')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].version, '3')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].vrf, 'red')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].security, 'priv')

    receiver.destroy
    refute_includes(Cisco::SnmpNotificationReceiver.receivers, id)
  end

  def test_create_destroy_multiple
    id = '4.5.6.7'
    id2 = '8.9.10.11'

    refute_includes(Cisco::SnmpNotificationReceiver.receivers, id)
    refute_includes(Cisco::SnmpNotificationReceiver.receivers, id2)

    receiver = \
      Cisco::SnmpNotificationReceiver.new(id,
                                          instantiate:      true,
                                          type:             'informs',
                                          version:          '3',
                                          security:         'priv',
                                          username:         'ab',
                                          port:             '45',
                                          vrf:              'red',
                                          source_interface: 'ethernet1/3')

    receiver2 = \
      Cisco::SnmpNotificationReceiver.new(id2,
                                          instantiate:      true,
                                          type:             'traps',
                                          version:          '3',
                                          security:         'auth',
                                          username:         'cd',
                                          port:             '46',
                                          vrf:              'red',
                                          source_interface: 'ethernet1/4')

    assert_includes(Cisco::SnmpNotificationReceiver.receivers, id)
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id], receiver)

    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].source_interface,
                 'ethernet1/3')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].port, '45')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].type, 'informs')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].username, 'ab')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].version, '3')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].vrf, 'red')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id].security, 'priv')

    assert_includes(Cisco::SnmpNotificationReceiver.receivers, id2)
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id2], receiver2)

    assert_equal(
      Cisco::SnmpNotificationReceiver.receivers[id2].source_interface,
      'ethernet1/4')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id2].port, '46')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id2].type, 'traps')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id2].username, 'cd')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id2].version, '3')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id2].vrf, 'red')
    assert_equal(Cisco::SnmpNotificationReceiver.receivers[id2].security,
                 'auth')

    receiver.destroy
    receiver2.destroy
    refute_includes(Cisco::SnmpNotificationReceiver.receivers, id)
    refute_includes(Cisco::SnmpNotificationReceiver.receivers, id2)
  end
end
