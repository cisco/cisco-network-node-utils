#
# Minitest for SyslogServer class
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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/syslog_server', __FILE__)

# TestSyslogServer - Minitest for SyslogServer node utility.
class TestSyslogServer < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_syslogserver
  end

  def teardown
    # teardown runs at the end of each test
    no_syslogserver
    super
  end

  def no_syslogserver
    # Turn the feature off for a clean test.
    config('no logging server 1.2.3.4',
           'no logging server 2.3.4.5',
           'no vrf context red')
  end

  # TESTS

  def test_syslogserver_create_destroy_single
    id = '1.2.3.4'
    refute_includes(Cisco::SyslogServer.syslogservers, id)

    server = Cisco::SyslogServer.new(id, 2, 'default', true)
    assert_includes(Cisco::SyslogServer.syslogservers, id)
    assert_equal(Cisco::SyslogServer.syslogservers[id], server)

    server.destroy
    refute_includes(Cisco::SyslogServer.syslogservers, id)
  end

  def test_syslogserver_create_destroy_multiple
    id = '1.2.3.4'
    id2 = '2.3.4.5'
    refute_includes(Cisco::SyslogServer.syslogservers, id)
    refute_includes(Cisco::SyslogServer.syslogservers, id2)

    server = Cisco::SyslogServer.new(id, 2, 'default', true)
    server2 = Cisco::SyslogServer.new(id2, 2, 'default', true)
    assert_includes(Cisco::SyslogServer.syslogservers, id)
    assert_equal(Cisco::SyslogServer.syslogservers[id], server)
    assert_includes(Cisco::SyslogServer.syslogservers, id2)
    assert_equal(Cisco::SyslogServer.syslogservers[id], server2)

    server.destroy
    server2.destroy
    refute_includes(Cisco::SyslogServer.syslogservers, id)
    refute_includes(Cisco::SyslogServer.syslogservers, id2)
  end

  def test_syslogserver_create_destroy_single_vrf
    config('vrf context red')
    id = '1.2.3.4'

    refute_includes(Cisco::SyslogServer.syslogservers, id)

    server = Cisco::SyslogServer.new(id, 2, 'red', true)
    assert_includes(Cisco::SyslogServer.syslogservers, id)
    assert_equal(Cisco::SyslogServer.syslogservers[id], server)

    server.destroy
    refute_includes(Cisco::SyslogServer.syslogservers, id)
  end
end
