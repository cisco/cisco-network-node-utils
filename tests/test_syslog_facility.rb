#
# Minitest for SyslogFacility class
#
# Copyright (c) 2014-2018 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/syslog_facility'

# TestSyslogFacility - Minitest for SyslogFacility node utility.
class TestSyslogFacility < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_syslogfacility
  end

  def teardown
    # teardown runs at the end of each test
    no_syslogfacility
    super
  end

  def no_syslogfacility
    # Turn the feature off for a clean test.
    config('no logging level aaa 6',
           'no logging level ip igmp 6',
           'no logging level routing ipv4 multicast 7')
  end

  # TESTS

  def test_create_destroy
    id = 'aaa'
    refute_includes(Cisco::SyslogFacility.facilities, id)

    facility = Cisco::SyslogFacility.new({ 'facility' => id, 'level' => 6 }, true)
    assert_includes(Cisco::SyslogFacility.facilities, id)
    assert_equal(Cisco::SyslogFacility.facilities[id], facility)
    assert_equal(id, Cisco::SyslogFacility.facilities[id].facility)
    assert_equal(6, Cisco::SyslogFacility.facilities[id].level)

    facility.destroy
    refute_includes(Cisco::SyslogFacility.facilities, id)
  end

  def test_create_destroy_extended
    id = 'ip igmp'
    id2 = 'routing ipv4 multicast'
    refute_includes(Cisco::SyslogFacility.facilities, id)
    refute_includes(Cisco::SyslogFacility.facilities, id2)

    facility = Cisco::SyslogFacility.new({ 'facility' => id, 'level' => 6 }, true)
    facility2 = Cisco::SyslogFacility.new({ 'facility' => id2, 'level' => 7 }, true)
    assert_includes(Cisco::SyslogFacility.facilities, id)
    assert_equal(Cisco::SyslogFacility.facilities[id], facility)
    assert_equal(id, Cisco::SyslogFacility.facilities[id].facility)
    assert_equal(6, Cisco::SyslogFacility.facilities[id].level)
    assert_includes(Cisco::SyslogFacility.facilities, id2)
    assert_equal(Cisco::SyslogFacility.facilities[id2], facility2)
    assert_equal(id2, Cisco::SyslogFacility.facilities[id2].facility)
    assert_equal(7, Cisco::SyslogFacility.facilities[id2].level)

    facility.destroy
    facility2.destroy
    refute_includes(Cisco::SyslogFacility.facilities, id)
    refute_includes(Cisco::SyslogFacility.facilities, id2)
  end
end
